/******************************************************************************
 * Spine Runtimes Software License v2.5
 *
 * Copyright (c) 2013-2016, Esoteric Software
 * All rights reserved.
 *
 * You are granted a perpetual, non-exclusive, non-sublicensable, and
 * non-transferable license to use, install, execute, and perform the Spine
 * Runtimes software and derivative works solely for personal or internal
 * use. Without the written permission of Esoteric Software (see Section 2 of
 * the Spine Software License Agreement), you may not (a) modify, translate,
 * adapt, or develop new applications using the Spine Runtimes or otherwise
 * create derivative works or improvements of the Spine Runtimes or (b) remove,
 * delete, alter, or obscure any trademarks or any copyright, trademark, patent,
 * or other intellectual property or proprietary rights notices on or in the
 * Software, including any copy thereof. Redistributions in binary or source
 * form must include this license and terms.
 *
 * THIS SOFTWARE IS PROVIDED BY ESOTERIC SOFTWARE "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL ESOTERIC SOFTWARE BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES, BUSINESS INTERRUPTION, OR LOSS OF
 * USE, DATA, OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
 * IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *****************************************************************************/
#include <spine/SkeletonTwoColorBatch.h>
#include <spine/extension.h>
#include <algorithm>

USING_NS_CC;
#define EVENT_AFTER_DRAW_RESET_POSITION "director_after_draw"
using std::max;
#define INITIAL_SIZE 1000
#define MAX_VERTICES 64000
#define MAX_INDICES 64000

#define STRINGIFY(A)  #A

namespace spine {

TwoColorTrianglesCommand::TwoColorTrianglesCommand() :_materialID(0), _textureID(0), _glProgramState(nullptr), _glProgram(nullptr), _blendType(BlendFunc::DISABLE), _alphaTextureID(0) {
	_type = RenderCommand::Type::CUSTOM_COMMAND;
	_transformed = false;
	_forceFlush = false;
	func = [this]() { draw(); };
}

void TwoColorTrianglesCommand::init(float globalOrder, GLuint textureID, GLProgramState* glProgramState, BlendFunc blendType, const TwoColorTriangles& triangles, const Mat4& mv, uint32_t flags) {
	CCASSERT(glProgramState, "Invalid GLProgramState");
	CCASSERT(glProgramState->getVertexAttribsFlags() == 0, "No custom attributes are supported in QuadCommand");

	RenderCommand::init(globalOrder, mv, flags);

	_triangles = triangles;
	if(_triangles.indexCount % 3 != 0) {
	int count = _triangles.indexCount;
		_triangles.indexCount = count / 3 * 3;
		CCLOGERROR("Resize indexCount from %zd to %zd, size must be multiple times of 3", count, _triangles.indexCount);
	}
	_mv = mv;

	if( _textureID != textureID || _blendType.src != blendType.src || _blendType.dst != blendType.dst ||
		_glProgramState != glProgramState ||
		_glProgram != glProgramState->getGLProgram()) {
		_textureID = textureID;
		_blendType = blendType;
		_glProgramState = glProgramState;
		_glProgram = glProgramState->getGLProgram();

		generateMaterialID();
	}
}

void TwoColorTrianglesCommand::init(float globalOrder, Texture2D* texture, GLProgramState* glProgramState, BlendFunc blendType, const TwoColorTriangles& triangles, const Mat4& mv, uint32_t flags) {
	init(globalOrder, texture->getName(), glProgramState, blendType, triangles, mv, flags);
	_alphaTextureID = texture->getAlphaTextureName();
}

TwoColorTrianglesCommand::~TwoColorTrianglesCommand() {
}

void TwoColorTrianglesCommand::generateMaterialID() {
	// do not batch if using custom uniforms (since we cannot batch) it
	if(_glProgramState->getUniformCount() > 0) {
		_materialID = Renderer::MATERIAL_ID_DO_NOT_BATCH;
		setSkipBatching(true);
	}
	else {
		int glProgram = (int)_glProgram->getProgram();		
		_materialID = glProgram + (int)_textureID + (int)_alphaTextureID + (int)_blendType.src + (int)_blendType.dst;
	}
}

void TwoColorTrianglesCommand::useMaterial() const {
	//Set texture
	GL::bindTexture2D(_textureID);

	if (_alphaTextureID > 0) {
		// ANDROID ETC1 ALPHA supports.
		GL::bindTexture2DN(1, _alphaTextureID);
	}

	//set blend mode
	GL::blendFunc(_blendType.src, _blendType.dst);

	_glProgramState->apply(_mv);
}
	
void TwoColorTrianglesCommand::draw() {
	SkeletonTwoColorBatch::getInstance()->batch(this);
}

void TwoColorTrianglesCommand::modelViewTransform() {
	if (_transformed) {
		return;
	}

	// move from SkeletonTwoColorBatch::batch
	auto verts = _triangles.verts;

	for (int i = 0; i < _triangles.vertCount; i++) {
		_mv.transformPoint(&verts[i].position);
	}

	_transformed = true;
}

//////////////////////////////////////////////////////////////////////////

std::vector<BatchThreadPool*> BatchThreadPool::_pool;
std::vector<BatchThreadPool*> BatchThreadPool::_autoreleaseVec;
std::mutex BatchThreadPool::_mutex;
BatchThreadPool* BatchThreadPool::_mainPool;
std::size_t BatchThreadPool::_mainThreadID;

void BatchThreadPool::init()
{
	std::hash<std::thread::id> threadHasher;
	_mainThreadID = threadHasher(std::this_thread::get_id());
	_mainPool = new BatchThreadPool(_mainThreadID);
}

// get and retain
BatchThreadPool* BatchThreadPool::getPool(std::size_t threadID, SkeletonRenderer* owner)
{
	if (threadID == _mainThreadID)
		return _mainPool;

	std::lock_guard<std::mutex> lock(_mutex);

	for (BatchThreadPool* pool : _pool) {
		if (pool->_ref == 0) {
			CCASSERT(pool->_ref == 0, "ref must equal 0");
			CCASSERT(pool->_lastCommands.empty(), "_lastCommands must empty");

			pool->_owner = owner;
			pool->_threadID = threadID;
			pool->retain();
			return pool;
		}
	}

	BatchThreadPool* pool = new BatchThreadPool(threadID);
	_pool.push_back(pool);
	pool->_owner = owner;
	pool->_threadID = threadID;
	pool->retain();
	return pool;
}

void BatchThreadPool::onSwitchDisableThread()
{
	if (Director::getInstance()->isSpineThreadDrawEnabled())
		return;

	std::lock_guard<std::mutex> lock(_mutex);

	int count = _pool.size();
	for (int i = _pool.size() - 1; i >= 0; --i) {
		BatchThreadPool* pool = _pool[i];
		// reserved 10 pool
		if (pool->_ref <= 0 && count > 10) {
			_pool[i] = nullptr;
			delete pool;
			--count;
		}
	}

	std::vector<BatchThreadPool*> newPool;
	for (BatchThreadPool* pool : _pool) {
		if (pool != nullptr) {
			newPool.push_back(pool);
		}
	}

	_pool = newPool;
}

void BatchThreadPool::resetMainFree()
{
	_mainPool->reset();
}

void BatchThreadPool::autoreleaseAll()
{
	for (BatchThreadPool* pool : _autoreleaseVec) {
		pool->release();
	}
	_autoreleaseVec.clear();
}

void BatchThreadPool::autoreleaseAfterDraw(BatchThreadPool* pool)
{
	_autoreleaseVec.push_back(pool);
}

// only used in thread
void BatchThreadPool::retain()
{
	_ref++;
}

// only used in thread
void BatchThreadPool::release()
{
	_ref--;
	int zero = 0;
	if (_ref.compare_exchange_strong(zero, -1)) {
		reset(); // _ref = 0 in reset
	}
}

BatchThreadPool::BatchThreadPool(std::size_t threadID)
{
	_threadID = threadID;
	_ref = 0;
	_owner = nullptr;

	// small pool for thread draw
	if (threadID != _mainThreadID)
	{
		for (unsigned int i = 0; i < 50; i++) {
			_commandsPool.push_back(new TrianglesCommand());
		}

		for (unsigned int i = 0; i < 50; i++) {
			_twoColorCommandsPool.push_back(new TwoColorTrianglesCommand());
		}

		_vertices.resize(500);
		_twoColorVertices.resize(500);

		_indices = spUnsignedShortArray_create(300);
	}
	else
	{
		for (unsigned int i = 0; i < INITIAL_SIZE; i++) {
			_commandsPool.push_back(new TrianglesCommand());
		}

		for (unsigned int i = 0; i < INITIAL_SIZE; i++) {
			_twoColorCommandsPool.push_back(new TwoColorTrianglesCommand());
		}

		_vertices.resize(10000);
		_twoColorVertices.resize(10000);

		_indices = spUnsignedShortArray_create(6000);
	}

	reset();
}

//////////////////////////////////////////////////////////////////////////
// for TrianglesCommand

cocos2d::TrianglesCommand* BatchThreadPool::nextFreeCommand() {
	if (_commandsPool.size() <= _nextFreeCommand) {
		unsigned int newSize = _commandsPool.size() * 2 + 1;
		for (int i = _commandsPool.size(); i < newSize; i++) {
			_commandsPool.push_back(new TrianglesCommand());
		}
	}
	return _commandsPool[_nextFreeCommand++];
}

cocos2d::V3F_C4B_T2F* BatchThreadPool::allocateVertices(uint32_t numVertices) {
	if (_vertices.size() - _numVertices < numVertices) {
		cocos2d::V3F_C4B_T2F* oldData = _vertices.data();
		_vertices.resize((_vertices.size() + numVertices) * 2 + 1);
		cocos2d::V3F_C4B_T2F* newData = _vertices.data();
		for (uint32_t i = 0; i < this->_nextFreeCommand; i++) {
			TrianglesCommand* command = _commandsPool[i];
			cocos2d::TrianglesCommand::Triangles& triangles = (cocos2d::TrianglesCommand::Triangles&)command->getTriangles();
			triangles.verts = newData + (triangles.verts - oldData);
		}
	}

	cocos2d::V3F_C4B_T2F* vertices = _vertices.data() + _numVertices;
	_numVertices += numVertices;
	return vertices;
}

void BatchThreadPool::deallocateVertices(uint32_t numVertices) {
	_numVertices -= numVertices;
}


//////////////////////////////////////////////////////////////////////////
// for TwoColorTrianglesCommand

TwoColorTrianglesCommand* BatchThreadPool::nextFreeTwoColorCommand() {
	if (_twoColorCommandsPool.size() <= _twoColorNextFreeCommand) {
		unsigned int newSize = _twoColorCommandsPool.size() * 2 + 1;
		for (int i = _twoColorCommandsPool.size(); i < newSize; i++) {
			_twoColorCommandsPool.push_back(new TwoColorTrianglesCommand());
		}
	}
	TwoColorTrianglesCommand* command = _twoColorCommandsPool[_twoColorNextFreeCommand++];
	command->setForceFlush(false);
	command->setModelViewTransformed(false);
	return command;
}

V3F_C4B_C4B_T2F* BatchThreadPool::allocateTwoColorVertices(uint32_t numVertices)
{
	if (_twoColorVertices.size() - _twoColorNumVertices < numVertices) {
		V3F_C4B_C4B_T2F* oldData = _twoColorVertices.data();
		_twoColorVertices.resize((_twoColorVertices.size() + numVertices) * 2 + 1);
		V3F_C4B_C4B_T2F* newData = _twoColorVertices.data();
		for (uint32_t i = 0; i < this->_twoColorNextFreeCommand; i++) {
			TwoColorTrianglesCommand* command = _twoColorCommandsPool[i];
			TwoColorTriangles& triangles = (TwoColorTriangles&)command->getTriangles();
			triangles.verts = newData + (triangles.verts - oldData);
		}
	}

	V3F_C4B_C4B_T2F* vertices = _twoColorVertices.data() + _twoColorNumVertices;
	_twoColorNumVertices += numVertices;
	return vertices;
}

void BatchThreadPool::deallocateTwoColorVertices(uint32_t numVertices)
{
	_twoColorNumVertices -= numVertices;
}

//////////////////////////////////////////////////////////////////////////
// for TrianglesCommand and TwoColorTrianglesCommand
unsigned short* BatchThreadPool::allocateIndices(uint32_t numIndices) {
	if (_indices->capacity - _indices->size < numIndices) {
		unsigned short* oldData = _indices->items;
		int oldSize = _indices->size;
		spUnsignedShortArray_ensureCapacity(_indices, _indices->size + numIndices);

		unsigned short* newData = _indices->items;
		for (uint32_t i = 0; i < this->_nextFreeCommand; i++) {
			TrianglesCommand* command = _commandsPool[i];
			cocos2d::TrianglesCommand::Triangles& triangles = (cocos2d::TrianglesCommand::Triangles&)command->getTriangles();
			if (triangles.indices >= oldData && triangles.indices < oldData + oldSize) {
				triangles.indices = newData + (triangles.indices - oldData);
			}
		}

		newData = _indices->items;
		for (uint32_t i = 0; i < this->_twoColorNextFreeCommand; i++) {
			TwoColorTrianglesCommand* command = _twoColorCommandsPool[i];
			TwoColorTriangles& triangles = (TwoColorTriangles&)command->getTriangles();
			if (triangles.indices >= oldData && triangles.indices < oldData + oldSize) {
				triangles.indices = newData + (triangles.indices - oldData);
			}
		}
	}

	unsigned short* indices = _indices->items + _indices->size;
	_indices->size += numIndices;
	return indices;
}

void BatchThreadPool::deallocateIndices(uint32_t numIndices) {
	_indices->size -= numIndices;
}


BatchThreadPool::~BatchThreadPool()
{
	for (unsigned int i = 0; i < _commandsPool.size(); i++) {
		delete _commandsPool[i];
	}
	_commandsPool.clear();

	for (unsigned int i = 0; i < _twoColorCommandsPool.size(); i++) {
		delete _twoColorCommandsPool[i];
	}
	_twoColorCommandsPool.clear();

	if (_indices) {
		spUnsignedShortArray_dispose(_indices);
		_indices = nullptr;
	}
}

void BatchThreadPool::reset()
{
	_nextFreeCommand = 0;
	_numVertices = 0;

	_twoColorNextFreeCommand = 0;
	_twoColorNumVertices = 0;

	_indices->size = 0;

	_lastCommands.clear();

	_threadID = 0;
	_owner = nullptr;

	_ref = 0;
}

void BatchThreadPool::transformLastCommands()
{
	for (RenderCommand* cmd : _lastCommands)
	{
		TwoColorTrianglesCommand* twoColorCmd = dynamic_cast<TwoColorTrianglesCommand*>(cmd);
		if (twoColorCmd)
		{
			twoColorCmd->modelViewTransform();
		}
	}
}

//////////////////////////////////////////////////////////////////////////

const char* TWO_COLOR_TINT_VERTEX_SHADER = STRINGIFY(
attribute vec4 a_position;
attribute vec4 a_color;
attribute vec4 a_color2;
attribute vec2 a_texCoords;

\n#ifdef GL_ES\n
varying lowp vec4 v_light;
varying lowp vec4 v_dark;
varying mediump vec2 v_texCoord;
\n#else\n
varying vec4 v_light;
varying vec4 v_dark;
varying vec2 v_texCoord;

\n#endif\n

void main() {
	v_light = a_color;
	v_dark = a_color2;
	v_texCoord = a_texCoords;
	gl_Position = CC_PMatrix * a_position;
}
);

const char* TWO_COLOR_TINT_FRAGMENT_SHADER = STRINGIFY(
\n#ifdef GL_ES\n
precision lowp float;
\n#endif\n

varying vec4 v_light;
varying vec4 v_dark;
varying vec2 v_texCoord;

void main() {
	vec4 texColor = texture2D(CC_Texture0, v_texCoord);
	float alpha = texColor.a * v_light.a;
	gl_FragColor.a = alpha;	
	gl_FragColor.rgb = ((texColor.a - 1.0) * v_dark.a + 1.0 - texColor.rgb) * v_dark.rgb + texColor.rgb * v_light.rgb;
}
);

const char* TWO_COLOR_TINT_WITH_ALPHA_TEX_FRAGMENT_SHADER = STRINGIFY(
\n#ifdef GL_ES\n
precision lowp float;
\n#endif\n

varying vec4 v_light;
varying vec4 v_dark;
varying vec2 v_texCoord;

void main() {
	vec4 texColor = texture2D(CC_Texture0, v_texCoord);
	texColor.a = texture2D(CC_Texture1, v_texCoord).a;

	float alpha = texColor.a * v_light.a;
	gl_FragColor.a = alpha;
	gl_FragColor.rgb = ((texColor.a - 1.0) * v_dark.a + 1.0 - texColor.rgb) * v_dark.rgb + texColor.rgb * v_light.rgb;
}
);

static SkeletonTwoColorBatch* instance = nullptr;

SkeletonTwoColorBatch* SkeletonTwoColorBatch::getInstance () {
	if (!instance) instance = new SkeletonTwoColorBatch();
	return instance;
}

void SkeletonTwoColorBatch::destroyInstance () {
	if (instance) {
		delete instance;
		instance = nullptr;
	}
}

SkeletonTwoColorBatch::SkeletonTwoColorBatch () {
	reset ();
	
	// callback after drawing is finished so we can clear out the batch state
	// for the next frame
	Director::getInstance()->getEventDispatcher()->addCustomEventListener(EVENT_AFTER_DRAW_RESET_POSITION, [this](EventCustom* eventCustom){
		this->update(0);
	});;
	
	_twoColorTintShader = cocos2d::GLProgram::createWithByteArrays(TWO_COLOR_TINT_VERTEX_SHADER, TWO_COLOR_TINT_FRAGMENT_SHADER);
	_twoColorTintShaderState = GLProgramState::getOrCreateWithGLProgram(_twoColorTintShader);
	_twoColorTintShaderState->retain();

	_twoColorTintWithAlphaTexShader = cocos2d::GLProgram::createWithByteArrays(TWO_COLOR_TINT_VERTEX_SHADER, TWO_COLOR_TINT_WITH_ALPHA_TEX_FRAGMENT_SHADER);
	_twoColorTintWithAlphaTexShaderState = GLProgramState::getOrCreateWithGLProgram(_twoColorTintWithAlphaTexShader);
	_twoColorTintWithAlphaTexShaderState->retain();
	
	glGenBuffers(1, &_vertexBufferHandle);
	_vertexBuffer = new V3F_C4B_C4B_T2F[MAX_VERTICES];
	glGenBuffers(1, &_indexBufferHandle);
	_indexBuffer = new unsigned short[MAX_INDICES];
	_positionAttributeLocation = _twoColorTintShader->getAttribLocation("a_position");
	_colorAttributeLocation = _twoColorTintShader->getAttribLocation("a_color");
	_color2AttributeLocation = _twoColorTintShader->getAttribLocation("a_color2");
	_texCoordsAttributeLocation = _twoColorTintShader->getAttribLocation("a_texCoords");
}

SkeletonTwoColorBatch::~SkeletonTwoColorBatch () {
	Director::getInstance()->getEventDispatcher()->removeCustomEventListeners(EVENT_AFTER_DRAW_RESET_POSITION);
	
	_twoColorTintShader->release();
	_twoColorTintWithAlphaTexShader->release();
	delete _vertexBuffer;
	delete _indexBuffer;
}

void SkeletonTwoColorBatch::update (float delta) {	
	reset();
}

TwoColorTrianglesCommand* SkeletonTwoColorBatch::addCommand(BatchThreadPool* pool, cocos2d::Renderer* renderer, float globalOrder, cocos2d::Texture2D* texture, cocos2d::GLProgramState* glProgramState, cocos2d::BlendFunc blendType, const TwoColorTriangles& triangles, const cocos2d::Mat4& mv, uint32_t flags) {
	TwoColorTrianglesCommand* command = pool->nextFreeTwoColorCommand();
	command->init(globalOrder, texture, glProgramState, blendType, triangles, mv, flags);
	renderer->addCommand(command);
	return command;
}

TwoColorTrianglesCommand* SkeletonTwoColorBatch::addCommandInThread(BatchThreadPool* pool, cocos2d::Renderer* renderer, float globalOrder, cocos2d::Texture2D* texture, cocos2d::GLProgramState* glProgramState, cocos2d::BlendFunc blendType, const TwoColorTriangles& triangles, const cocos2d::Mat4& mv, uint32_t flags) {
	TwoColorTrianglesCommand* command = pool->nextFreeTwoColorCommand();
	command->init(globalOrder, texture, glProgramState, blendType, triangles, mv, flags);
	pool->addCommandForRenderer(command);
	return command;
}

TwoColorTrianglesCommand* SkeletonTwoColorBatch::addCommandWithGroup(BatchThreadPool* pool, cocos2d::Renderer* renderer, int groupID, float globalOrder, cocos2d::Texture2D* texture, cocos2d::GLProgramState* glProgramState, cocos2d::BlendFunc blendType, const TwoColorTriangles& triangles, const cocos2d::Mat4& mv, uint32_t flags) {
	TwoColorTrianglesCommand* command = pool->nextFreeTwoColorCommand();
	command->init(globalOrder, texture, glProgramState, blendType, triangles, mv, flags);
	renderer->addCommand(command, groupID);
	return command;
}

// RGBA8888 AI88 in pvr.ccz already tested, its ok by huangwei 2020/5/28
// but A8 had wrong display, may be TexturePacker output bug
cocos2d::GLProgramState* SkeletonTwoColorBatch::getTwoColorTintProgramState(cocos2d::Texture2D* texture) { 
	if (texture && texture->getAlphaTextureName() > 0)
		return _twoColorTintWithAlphaTexShaderState;
	return _twoColorTintShaderState; 
}

cocos2d::GLProgramState* SkeletonTwoColorBatch::getTwoColorTintProgramState(bool hadAlphaTex) {
	if (hadAlphaTex)
		return _twoColorTintWithAlphaTexShaderState;
	return _twoColorTintShaderState;
}

void SkeletonTwoColorBatch::batch (TwoColorTrianglesCommand* command) {
	if (_numVerticesBuffer + command->getTriangles().vertCount >= MAX_VERTICES || _numIndicesBuffer + command->getTriangles().indexCount >= MAX_INDICES) {
		flush(_lastCommand);
	}
	
	uint32_t materialID = command->getMaterialID();
	if (_lastCommand && _lastCommand->getMaterialID() != materialID) {
		flush(_lastCommand);
	}
	
	// command->modelViewTransform();

	memcpy(_vertexBuffer + _numVerticesBuffer, command->getVertices(), sizeof(V3F_C4B_C4B_T2F) * command->getVertexCount());
 	const Mat4& modelView = command->getModelView();
	for (int i = _numVerticesBuffer; i < _numVerticesBuffer + command->getTriangles().vertCount; i++) {
		modelView.transformPoint(&_vertexBuffer[i].position);
	}
	
	unsigned short vertexOffset = (unsigned short)_numVerticesBuffer;
	unsigned short* indices = (unsigned short*)command->getIndices();
	int indexCount = command->getIndexCount();
	for (int i = 0, j = _numIndicesBuffer; i < indexCount; i++, j++) {
		_indexBuffer[j] = indices[i] + vertexOffset;
	}
	
	_numVerticesBuffer += command->getVertexCount();
	_numIndicesBuffer += command->getIndexCount();
	
	if (command->isForceFlush()) {
		flush(command);
	}
	_lastCommand = command;
}
	
void SkeletonTwoColorBatch::flush (TwoColorTrianglesCommand* materialCommand) {
	if (!materialCommand)
		return;
	
	materialCommand->useMaterial();
	
	glBindBuffer(GL_ARRAY_BUFFER, _vertexBufferHandle);
	glBufferData(GL_ARRAY_BUFFER, sizeof(V3F_C4B_C4B_T2F) * _numVerticesBuffer , _vertexBuffer, GL_DYNAMIC_DRAW);
	
	glEnableVertexAttribArray(_positionAttributeLocation);
	glEnableVertexAttribArray(_colorAttributeLocation);
	glEnableVertexAttribArray(_color2AttributeLocation);
	glEnableVertexAttribArray(_texCoordsAttributeLocation);
	
	glVertexAttribPointer(_positionAttributeLocation, 3, GL_FLOAT, GL_FALSE, sizeof(V3F_C4B_C4B_T2F), (GLvoid*)offsetof(V3F_C4B_C4B_T2F, position));
	glVertexAttribPointer(_colorAttributeLocation, 4, GL_UNSIGNED_BYTE, GL_TRUE, sizeof(V3F_C4B_C4B_T2F), (GLvoid*)offsetof(V3F_C4B_C4B_T2F, color));
	glVertexAttribPointer(_color2AttributeLocation, 4, GL_UNSIGNED_BYTE, GL_TRUE, sizeof(V3F_C4B_C4B_T2F), (GLvoid*)offsetof(V3F_C4B_C4B_T2F, color2));
	glVertexAttribPointer(_texCoordsAttributeLocation, 2, GL_FLOAT, GL_FALSE, sizeof(V3F_C4B_C4B_T2F), (GLvoid*)offsetof(V3F_C4B_C4B_T2F, texCoords));
	
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBufferHandle);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(unsigned short) * _numIndicesBuffer, _indexBuffer, GL_STATIC_DRAW);

	glDrawElements(GL_TRIANGLES, (GLsizei)_numIndicesBuffer, GL_UNSIGNED_SHORT, 0);
	
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);

	CC_INCREMENT_GL_DRAWN_BATCHES_AND_VERTICES(1, _numIndicesBuffer);
	
	_numVerticesBuffer = 0;
	_numIndicesBuffer = 0;
	_numBatches++;

	CHECK_GL_ERROR_DEBUG();
}

void SkeletonTwoColorBatch::reset() {
	_numVerticesBuffer = 0;
	_numIndicesBuffer = 0;
	_lastCommand = nullptr;
	_numBatches = 0;
}

}