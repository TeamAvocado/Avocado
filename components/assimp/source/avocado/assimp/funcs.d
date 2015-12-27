module avocado.assimp.funcs;

import avocado.assimp;

bool hasPositions(in aiMesh* mesh) {
	return mesh.mVertices !is null && mesh.mNumVertices > 0;
}

bool hasFaces(in aiMesh* mesh) {
	return mesh.mFaces !is null && mesh.mNumFaces > 0;
}

bool hasNormals(in aiMesh* mesh) {
	return mesh.mNormals !is null && mesh.mNumVertices > 0;
}

bool hasTangentsAndBitangents(in aiMesh* mesh) {
	return mesh.mTangents !is null && mesh.mBitangents !is null && mesh.mNumVertices > 0;
}

bool hasVertexColors(in aiMesh* mesh, uint pIndex) {
	if (pIndex >= AI_MAX_NUMBER_OF_COLOR_SETS)
		return false;
	else
		return mesh.mColors[pIndex] !is null && mesh.mNumVertices > 0;
}

bool hasTextureCoords(in aiMesh* mesh, uint pIndex) {
	if (pIndex >= AI_MAX_NUMBER_OF_TEXTURECOORDS)
		return false;
	else
		return mesh.mTextureCoords[pIndex] !is null && mesh.mNumVertices > 0;
}

uint getNumUVChannels(in aiMesh* mesh) {
	uint n = 0;
	while (n < AI_MAX_NUMBER_OF_TEXTURECOORDS && mesh.mTextureCoords[n])
		++n;
	return n;
}

uint getNumColorChannels(in aiMesh* mesh) {
	uint n = 0;
	while (n < AI_MAX_NUMBER_OF_COLOR_SETS && mesh.mColors[n])
		++n;
	return n;
}
