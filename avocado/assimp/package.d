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

struct AssimpVertexWeight {
    uint vertexID;
    float weight;
}

struct AssimpMeshBone {
    string name;
    mat4 offset;
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
    /// It's recommended to sort after faceSize for mesh creation for OpenGL rendering.
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

    float coneInnerAngle, coneOuterAngle;
    float attenuationConstant;
    float attenuationLinear;
    float attenuationQuadratic;
    vec3 ambientColor;
    vec3 diffuseColor;
    vec3 specularColor;
    vec3 direction;
    vec3 position;
    AssimpLightSourceType type;
}

///
struct AssimpScene {
    AssimpMeshData[] meshes;
    AssimpLightNode[] lights;
}

private auto toVec3(aiVector3D v) {
    return vec3(v.x, v.y, v.z);
}

private auto toVec4(aiColor4D v) {
    return vec4(v.r, v.g, v.b, v.a);
}

private auto toMat4(aiMatrix4x4 m) {
    with (m)
        return mat4(a1, a2, a3, a4, b1, b2, b3, b4, c1, c2, c3, c4, d1, d2, d3, d4);
}

private auto str(aiString s) {
    return s.data[0 .. s.length].idup;
}

private auto toWeights(in aiVertexWeight[] weights) {
    AssimpVertexWeight[] w;
    foreach (weight; weights)
        w ~= AssimpVertexWeight(weight.mVertexId, weight.mWeight);
    return w;
}

AssimpScene loadScene(string file,
    AssimpFlag flags = AssimpFlag.GenNormals | AssimpFlag.JoinIdenticalVertices | AssimpFlag.Triangulate | AssimpFlag.GenUVCoords | AssimpFlag.FlipUVs) {
    return aiImportFile(file.toStringz(), flags).toScene;
}

AssimpScene loadSceneFromMemory(ubyte[] buffer,
    AssimpFlag flags = AssimpFlag.GenNormals | AssimpFlag.JoinIdenticalVertices | AssimpFlag.Triangulate | AssimpFlag.GenUVCoords | AssimpFlag.FlipUVs,
    string hint = "") {
    return aiImportFileFromMemory(buffer.ptr, cast(uint) buffer.length, flags, hint.toStringz()).toScene;
}

private AssimpScene toScene(const aiScene* aScene) {
    AssimpScene scene;
    scene.meshes.length = aScene.mNumMeshes;

    for (int i = aScene.mNumMeshes - 1; i >= 0; i--) {
        auto aMesh = aScene.mMeshes[i];
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
                        scene.meshes[$ - 1 - i].texCoords[texChan] ~= aMesh.mTextureCoords[texChan][
                            vert].toVec3();
                    }
                }
            }
        }
        for (int face = 0; face < aMesh.mNumFaces; face++) {
            scene.meshes[$ - 1 - i].indices ~= cast(uint[]) aMesh.mFaces[face].mIndices[0
                .. aMesh.mFaces[face].mNumIndices];
        }
        for (int bone = 0; bone < aMesh.mNumBones; bone++) {
            auto b = aMesh.mBones[bone];
            scene.meshes[$ - 1 - i].bones ~= AssimpMeshBone(b.mName.str,
                b.mOffsetMatrix.toMat4, b.mWeights[0 .. b.mNumWeights].toWeights);
        }
    }

    scene.lights.length = aScene.mNumLights;
    for (int i = 0; i < aScene.mNumLights; i++) {
        auto aLight = aScene.mLights[i];
        scene.lights[i].name = aLight.mName.str;
        scene.lights[i].coneOuterAngle = aLight.mAngleOuterCone;
        scene.lights[i].attenuationConstant = aLight.mAttenuationConstant;
        scene.lights[i].attenuationLinear = aLight.mAttenuationLinear;
        scene.lights[i].attenuationQuadratic = aLight.mAttenuationQuadratic;
        scene.lights[i].direction = aLight.mDirection.toVec3;
        scene.lights[i].position = aLight.mPosition.toVec3;
        scene.lights[i].type = cast(AssimpLightSourceType) aLight.mType;
    }

    return scene;
}

/// Assimp Scene as resource
class Scene : IResourceProvider {
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
    bool canRead(string extension) {
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
