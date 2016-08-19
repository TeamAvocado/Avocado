module avocado.assimp;

import avocado.core.resource.resourceprovider;
import avocado.core.display.bitmap;
import avocado.core.util;

import std.string;

public import derelict.assimp3.assimp;
public import avocado.assimp.funcs;

enum AssimpFlag : uint {
	CalcTangentSpace = aiProcess_CalcTangentSpace,
	JoinIdenticalVertices = aiProcess_JoinIdenticalVertices,
	MakeLeftHanded = aiProcess_MakeLeftHanded,
	Triangulate = aiProcess_Triangulate,
	RemoveComponent = aiProcess_RemoveComponent,
	GenNormals = aiProcess_GenNormals,
	GenSmoothNormals = aiProcess_GenSmoothNormals,
	SplitLargeMeshes = aiProcess_SplitLargeMeshes,
	PreTransformVertices = aiProcess_PreTransformVertices,
	LimitBoneWeights = aiProcess_LimitBoneWeights,
	ValidateDataStructure = aiProcess_ValidateDataStructure,
	ImproveCacheLocality = aiProcess_ImproveCacheLocality,
	RemoveRedundantMaterials = aiProcess_RemoveRedundantMaterials,
	FixInFacingNormals = aiProcess_FixInFacingNormals,
	SortByPType = aiProcess_SortByPType,
	FindDegenerates = aiProcess_FindDegenerates,
	FindInvalidData = aiProcess_FindInvalidData,
	GenUVCoords = aiProcess_GenUVCoords,
	TransformUVCoords = aiProcess_TransformUVCoords,
	FindInstances = aiProcess_FindInstances,
	OptimizeMeshes = aiProcess_OptimizeMeshes,
	OptimizeGraph = aiProcess_OptimizeGraph,
	FlipUVs = aiProcess_FlipUVs,
	FlipWindingOrder = aiProcess_FlipWindingOrder,
	SplitByBoneCount = aiProcess_SplitByBoneCount,
	Debone = aiProcess_Debone,

	ConvertToLeftHanded = aiProcess_ConvertToLeftHanded,
	TargetRealtime_Fast = aiProcessPreset_TargetRealtime_Fast,
	TargetRealtime_Quality = aiProcessPreset_TargetRealtime_Quality,
}

///
struct AssimpVertexWeight {
	///
	uint vertexID;
	///
	float weight;
}

///
struct AssimpMeshBone {
	///
	string name;
	///
	mat4 offset;
	///
	AssimpVertexWeight[] weights;
}

///
struct AssimpMeshData {
	/// Name of the mesh.
	string name;

	/// The bitangent of a vertex points in the direction of the positive Y texture axis.
	vec3[] bitangents;
	/// The bones of this mesh.
	AssimpMeshBone[] bones;
	/// Vertex color sets.
	vec4[][] colors;
	/// Indices in format vertexID[faceSize][]
	/// It's recommended to sort by faceSize for mesh creation for OpenGL rendering.
	uint[][] indices;
	/// Vertex normals.
	vec3[] normals;
	/// The tangent of a vertex points in the direction of the positive X texture axis.
	vec3[] tangents;
	/// Vertex texture coords, also known as UV channels.
	vec3[][] texCoords;
	/// Vertex positions
	vec3[] vertices;
}

enum AssimpLightSourceType {
	Undefined = aiLightSourceType_UNDEFINED,
	Directional = aiLightSourceType_DIRECTIONAL,
	Point = aiLightSourceType_POINT,
	Spot = aiLightSourceType_SPOT
}

///
struct AssimpLightNode {
	/// Name of the light node.
	string name;

	///
	float coneInnerAngle, coneOuterAngle;
	///
	float attenuationConstant;
	///
	float attenuationLinear;
	///
	float attenuationQuadratic;
	///
	vec3 ambientColor;
	///
	vec3 diffuseColor;
	///
	vec3 specularColor;
	///
	vec3 direction;
	///
	vec3 position;
	///
	AssimpLightSourceType type;
}

///
enum AssimpAnimationBehaviour {
	Default = aiAnimBehaviour_DEFAULT,
	Constant = aiAnimBehaviour_CONSTANT,
	Linear = aiAnimBehaviour_LINEAR,
	Repeat = aiAnimBehaviour_REPEAT
}

/// A time-value pair specifying `T` for the given time
struct AssimpKeyframe(T) {
	/// Time in ticks
	float time;
	/// Value at this keyframe
	T value;
}

private auto findKeyframeIndex(T)(in AssimpKeyframe!(T)[] keyframes, float time) {
	assert(keyframes.length > 0);
	foreach (i, keyframe; keyframes)
		if (time < keyframe.time)
			return i;
	return keyframes.length;
}

/// Interpolates between rotation keyframes using `nlerp` and returns the value at `time`
T interpolate(T)(in AssimpKeyframe!(T)[] keyframes, float time) if (is_quaternion!T) {
	return keyframes.interpolate!(T, nlerp)(time);
}

/// Interpolates between keyframes using a lerp function and returns the value at `time`
T interpolate(T, alias lerpFunc = lerp)(in AssimpKeyframe!(T)[] keyframes, float time) {
	assert(keyframes.length > 0);
	const index = keyframes.findKeyframeIndex(time);
	if (index == keyframes.length)
		return keyframes[index].value;
	const prevIndex = index - 1;
	const deltaTime = keyframes[index].time - keyframes[prevIndex].time;
	const factor = (time - keyframes[prevIndex].time) / deltaTime;
	const start = keyframes[prevIndex].value;
	const end = keyframes[index].value;
	return lerpFunc(start, end, factor);
}

///
alias AssimpVectorKeyframe = AssimpKeyframe!vec3;
///
alias AssimpQuaternionKeyframe = AssimpKeyframe!quat;
///
alias AssimpMeshIndexKeyframe = AssimpKeyframe!uint;

/// Animation of a single node/bone. Also called bone channel.
struct AssimpBoneAnimation {
	///
	string nodeName;
	///
	AssimpVectorKeyframe[] positionKeyframes;
	///
	AssimpVectorKeyframe[] scalingKeyframes;
	///
	AssimpQuaternionKeyframe[] rotationKeyframes;
	//AssimpAnimationBehaviour preState;
	//AssimpAnimationBehaviour postState;
}

/// Vertex-based deformation of one or more meshes. Also called mesh channel.
struct AssimpMeshAnimation {
	///
	string meshName;
	///
	AssimpMeshIndexKeyframe[] keys;
}

/// Finds the bone channel with the name `name` in `channels`
AssimpBoneAnimation* findNode(AssimpBoneAnimation[] channels, string name) {
	foreach (ref channel; channels)
		if (channel.nodeName == name)
			return &channel;
	return null;
}

/// Finds the mesh channel with the name `name` in `channels`
AssimpMeshAnimation* findNode(AssimpMeshAnimation[] channels, string name) {
	foreach (ref channel; channels)
		if (channel.meshName == name)
			return &channel;
	return null;
}

///
struct AssimpAnimation {
	/// Bone keyframes
	AssimpBoneAnimation[] boneChannels;
	/// Shape animation
	AssimpMeshAnimation[] meshChannels;
	///
	float durationInTicks;
	///
	float ticksPerSecond;
	///
	string name;
}

///
struct AssimpNode {
	///
	string name;
	///
	AssimpNode*[] children;
	///
	uint[] meshIndices;
	///
	mat4 transform;
	///
	AssimpNode* parent;

	/// Creates this assimp node from an aiNode
	this(in aiNode node, AssimpNode* parent = null) {
		name = node.mName.str;
		meshIndices.length = node.mNumMeshes;
		for (int i = 0; i < node.mNumMeshes; i++)
			meshIndices[i] = node.mMeshes[i];
		transform = node.mTransformation.toMat4;
		children.length = node.mNumChildren;
		for (int i = 0; i < node.mNumChildren; i++)
			if (node.mChildren[i])
				children[i] = new AssimpNode(*node.mChildren[i], &this);
	}

	AssimpNode* getChild(string name, bool recursive = false) {
		foreach (child; children)
		{
			if (!child)
				continue;
			if (child.name == name)
				return child;
			if (recursive)
			{
				auto ret = child.getChild(name, recursive);
				if (ret)
					return ret;
			}
		}
		return null;
	}
}

///
struct AssimpScene {
	///
	AssimpMeshData[] meshes;
	///
	AssimpLightNode[] lights;
	///
	AssimpAnimation[] animations;
	///
	AssimpNode* rootNode;
}

private auto toVec3(aiVector3D v) {
	return vec3(v.x, v.y, v.z);
}

private auto toVec4(aiColor4D v) {
	return vec4(v.r, v.g, v.b, v.a);
}

private auto toQuat(aiQuaternion v) {
	return quat(v.w, v.x, v.y, v.z);
}

private auto toMat4(aiMatrix4x4 m) {
	with (m)
		return mat4(a1, a2, a3, a4, b1, b2, b3, b4, c1, c2, c3, c4, d1, d2, d3, d4);
}

private string str(aiString s) {
	if (!s.length)
		return "";
	return s.data[0 .. s.length].idup;
}

private auto toWeights(in aiVertexWeight[] weights) {
	AssimpVertexWeight[] w;
	foreach (weight; weights)
		w ~= AssimpVertexWeight(weight.mVertexId, weight.mWeight);
	return w;
}

/// Loads an assimp scene from a file
AssimpScene loadScene(string file,
	AssimpFlag flags = AssimpFlag.GenNormals | AssimpFlag.JoinIdenticalVertices | AssimpFlag.Triangulate
	| AssimpFlag.GenUVCoords | AssimpFlag.FlipUVs) {
	return aiImportFile(file.toStringz(), flags).toScene;
}

/// Loads an assimp scene from a memory buffer
AssimpScene loadSceneFromMemory(ubyte[] buffer,
	AssimpFlag flags = AssimpFlag.GenNormals | AssimpFlag.JoinIdenticalVertices | AssimpFlag.Triangulate
	| AssimpFlag.GenUVCoords | AssimpFlag.FlipUVs, string hint = "") {
	return aiImportFileFromMemory(buffer.ptr, cast(uint)buffer.length, flags, hint.toStringz()).toScene;
}

private AssimpScene toScene(const aiScene* aScene) {
	AssimpScene scene;

	assert(aScene, "Invalid Scene!");

	if (aScene.mRootNode)
		scene.rootNode = new AssimpNode(*aScene.mRootNode);

	scene.meshes.length = aScene.mNumMeshes;
	for (int i = aScene.mNumMeshes - 1; i >= 0; i--) {
		const aMesh = aScene.mMeshes[i];
		scene.meshes[$ - 1 - i].name = aMesh.mName.str;
		scene.meshes[$ - 1 - i].colors.length = aMesh.getNumColorChannels;
		scene.meshes[$ - 1 - i].texCoords.length = aMesh.getNumUVChannels;
		for (int vert = 0; vert < aMesh.mNumVertices; vert++) {
			if (aMesh.hasTangentsAndBitangents) {
				scene.meshes[$ - 1 - i].tangents ~= aMesh.mTangents[vert].toVec3;
				scene.meshes[$ - 1 - i].bitangents ~= aMesh.mBitangents[vert].toVec3;
			}
			if (aMesh.hasNormals) {
				scene.meshes[$ - 1 - i].normals ~= aMesh.mNormals[vert].toVec3;
			}
			if (aMesh.hasPositions) {
				scene.meshes[$ - 1 - i].vertices ~= aMesh.mVertices[vert].toVec3;
			}
			if (aMesh.getNumColorChannels > 0) {
				for (int colChan = 0; colChan < aMesh.getNumColorChannels; colChan++) {
					if (aMesh.hasVertexColors(colChan)) {
						scene.meshes[$ - 1 - i].colors[colChan] ~= aMesh.mColors[colChan][vert].toVec4();
					}
				}
			}
			if (aMesh.getNumUVChannels > 0) {
				for (int texChan = 0; texChan < aMesh.getNumUVChannels; texChan++) {
					if (aMesh.hasTextureCoords(texChan)) {
						scene.meshes[$ - 1 - i].texCoords[texChan] ~= aMesh.mTextureCoords[texChan][vert].toVec3();
					}
				}
			}
		}
		for (int face = 0; face < aMesh.mNumFaces; face++) {
			scene.meshes[$ - 1 - i].indices ~= cast(uint[])aMesh.mFaces[face].mIndices[0 .. aMesh.mFaces[face].mNumIndices];
		}
		for (int bone = 0; bone < aMesh.mNumBones; bone++) {
			const b = aMesh.mBones[bone];
			scene.meshes[$ - 1 - i].bones ~= AssimpMeshBone(b.mName.str, b.mOffsetMatrix.toMat4, b.mWeights[0 .. b.mNumWeights].toWeights);
		}
	}

	scene.lights.length = aScene.mNumLights;
	for (int i = 0; i < aScene.mNumLights; i++) {
		const aLight = aScene.mLights[i];
		scene.lights[i].name = aLight.mName.str;
		scene.lights[i].coneOuterAngle = aLight.mAngleOuterCone;
		scene.lights[i].attenuationConstant = aLight.mAttenuationConstant;
		scene.lights[i].attenuationLinear = aLight.mAttenuationLinear;
		scene.lights[i].attenuationQuadratic = aLight.mAttenuationQuadratic;
		scene.lights[i].direction = aLight.mDirection.toVec3;
		scene.lights[i].position = aLight.mPosition.toVec3;
		scene.lights[i].type = cast(AssimpLightSourceType)aLight.mType;
	}

	scene.animations.length = aScene.mNumAnimations;
	for (int i = 0; i < aScene.mNumAnimations; i++) {
		const aAnim = aScene.mAnimations[i];
		scene.animations[i].name = aAnim.mName.str;
		scene.animations[i].durationInTicks = aAnim.mDuration;
		scene.animations[i].ticksPerSecond = aAnim.mTicksPerSecond;
		scene.animations[i].boneChannels.length = aAnim.mNumChannels;
		scene.animations[i].meshChannels.length = aAnim.mNumMeshChannels;
		for (int chnlNum = 0; chnlNum < aAnim.mNumChannels; chnlNum++) {
			const aChnl = aAnim.mChannels[chnlNum];
			scene.animations[i].boneChannels[chnlNum].nodeName = aChnl.mNodeName.str;
			//scene.animations[i].boneChannels[chnlNum].preState = cast(AssimpAnimationBehaviour)aChnl.mPreState;
			//scene.animations[i].boneChannels[chnlNum].postState = cast(AssimpAnimationBehaviour)aChnl.mPostState;
			scene.animations[i].boneChannels[chnlNum].positionKeyframes.length = aChnl.mNumPositionKeys;
			scene.animations[i].boneChannels[chnlNum].rotationKeyframes.length = aChnl.mNumRotationKeys;
			scene.animations[i].boneChannels[chnlNum].scalingKeyframes.length = aChnl.mNumScalingKeys;
			for (int key = 0; key < aChnl.mNumPositionKeys; key++) {
				const aKey = aChnl.mPositionKeys[key];
				scene.animations[i].boneChannels[chnlNum].positionKeyframes[key].time = aKey.mTime;
				scene.animations[i].boneChannels[chnlNum].positionKeyframes[key].value = aKey.mValue.toVec3;
			}
			for (int key = 0; key < aChnl.mNumRotationKeys; key++) {
				const aKey = aChnl.mRotationKeys[key];
				scene.animations[i].boneChannels[chnlNum].rotationKeyframes[key].time = aKey.mTime;
				scene.animations[i].boneChannels[chnlNum].rotationKeyframes[key].value = aKey.mValue.toQuat;
			}
			for (int key = 0; key < aChnl.mNumScalingKeys; key++) {
				const aKey = aChnl.mScalingKeys[key];
				scene.animations[i].boneChannels[chnlNum].scalingKeyframes[key].time = aKey.mTime;
				scene.animations[i].boneChannels[chnlNum].scalingKeyframes[key].value = aKey.mValue.toVec3;
			}
		}
		for (int chnlNum = 0; chnlNum < aAnim.mNumMeshChannels; chnlNum++) {
			const aChnl = aAnim.mMeshChannels[chnlNum];
			scene.animations[i].meshChannels[chnlNum].meshName = aChnl.mName.str;
			scene.animations[i].meshChannels[chnlNum].keys.length = aChnl.mNumKeys;
			for (int key = 0; key < aChnl.mNumKeys; key++) {
				scene.animations[i].meshChannels[chnlNum].keys[key].time = aChnl.mKeys[key].mTime;
				scene.animations[i].meshChannels[chnlNum].keys[key].value = aChnl.mKeys[key].mValue;
			}
		}
	}

	return scene;
}

/// Assimp Scene as resource
class Scene : IResourceProvider {
	/// Contains the actual AssimpScene
	AssimpScene value;

	/// Unused
	void error() {
	}

	/// Unused
	@property string errorInfo() {
		return "";
	}

	/// Loads a AssimpScene from a memory stream
	bool load(ref ubyte[] stream) {
		value = loadSceneFromMemory(stream);
		return true;
	}

	/// Always returns true
	bool canRead(string) {
		return true;
	}

	/// Can cast to a AssimpScene
	T opCast(T)() if (is(T == AssimpScene)) {
		return value;
	}
}

shared static this() {
	DerelictASSIMP3.load();
}
