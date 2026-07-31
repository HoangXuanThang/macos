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

#ifndef SPINE_SKELETONTWOCOLORBATCH_H_
#define SPINE_SKELETONTWOCOLORBATCH_H_

#include <spine/spine.h>
#include "cocos2d.h"
#include <vector>
#include <mutex>
#include <cstdlib>
#include <vector>

#include "spine/SkeletonBatch.h"

namespace spine {

	class SkeletonRenderer;
	
	struct V3F_C4B_C4B_T2F {
		cocos2d::Vec3 position;
		cocos2d::Color4B color;
		cocos2d::Color4B color2;
		cocos2d::Tex2F texCoords;
	};

	struct TwoColorTriangles {
		V3F_C4B_C4B_T2F* verts;
		unsigned short* indices;
		int vertCount;
		int indexCount;
	};
	
	class TwoColorTrianglesCommand : public cocos2d::CustomCommand {
	public:
		TwoColorTrianglesCommand();
		
		~TwoColorTrianglesCommand();
	
		void init(float globalOrder, GLuint textureID, cocos2d::GLProgramState* glProgramState, cocos2d::BlendFunc blendType, const TwoColorTriangles& triangles, const cocos2d::Mat4& mv, uint32_t flags);
		void init(float globalOrder, cocos2d::Texture2D* texture, cocos2d::GLProgramState* glProgramState, cocos2d::BlendFunc blendType, const TwoColorTriangles& triangles, const cocos2d::Mat4& mv, uint32_t flags);

		void useMaterial() const;
		
		inline uint32_t getMaterialID() const { return _materialID; }
		
		inline GLuint getTextureID() const { return _textureID; }
		
		inline const TwoColorTriangles& getTriangles() const { return _triangles; }
		
		inline ssize_t getVertexCount() const { return _triangles.vertCount; }
		
		inline ssize_t getIndexCount() const { return _triangles.indexCount; }
		
		inline const V3F_C4B_C4B_T2F* getVertices() const { return _triangles.verts; }
		
		inline const unsigned short* getIndices() const { return _triangles.indices; }
		
		inline cocos2d::GLProgramState* getGLProgramState() const { return _glProgramState; }

		inline cocos2d::GLProgram* getGLProgram() const { return _glProgram; }
		
		inline cocos2d::BlendFunc getBlendType() const { return _blendType; }
		
		inline const cocos2d::Mat4& getModelView() const { return _mv; }
		
		void draw ();
		
		void setForceFlush (bool forceFlush) { _forceFlush = forceFlush; }
		
		bool isForceFlush () { return _forceFlush; }

		void setModelViewTransformed(bool transformed) { _transformed = transformed; }

		void modelViewTransform();
		
		bool isModelViewTransformed() { return _transformed; }

	protected:
		void generateMaterialID();

		uint32_t _materialID;
		GLuint _textureID;
		cocos2d::GLProgramState* _glProgramState;
		cocos2d::GLProgram* _glProgram;
		cocos2d::BlendFunc _blendType;
		TwoColorTriangles _triangles;
		cocos2d::Mat4 _mv;
		GLuint _alphaTextureID;
		bool _forceFlush;
		bool _transformed;
	};


	class BatchThreadPool {
	public:
		BatchThreadPool(std::size_t threadID);
		virtual ~BatchThreadPool();
		
		static void init();
		static BatchThreadPool* getPool(std::size_t threadID, SkeletonRenderer* owner);
		static void onSwitchDisableThread();
		static void resetMainFree();
		static void autoreleaseAll();
		static void autoreleaseAfterDraw(BatchThreadPool* pool);

		void reset();

		TwoColorTrianglesCommand* nextFreeTwoColorCommand();

		cocos2d::TrianglesCommand* nextFreeCommand();

		V3F_C4B_C4B_T2F* allocateTwoColorVertices(uint32_t numVertices);
		void deallocateTwoColorVertices(uint32_t numVertices);

		cocos2d::V3F_C4B_T2F* allocateVertices(uint32_t numVertices);
		void deallocateVertices(uint32_t numVertices);

		unsigned short* allocateIndices(uint32_t numIndices);
		void deallocateIndices(uint32_t numVertices);

		void retain();
		void release();
		void addCommandForRenderer(cocos2d::RenderCommand* cmd) { _lastCommands.push_back(cmd); }
		std::vector<cocos2d::RenderCommand*>& getLastCommandsForRenderer() { return _lastCommands; }
		void transformLastCommands();
		SkeletonRenderer* getOwner() { return _owner; }

	protected:
		// thread local cache
		static BatchThreadPool* _mainPool;
		static std::size_t _mainThreadID;
		static std::vector<BatchThreadPool*> _pool;
		static std::vector<BatchThreadPool*> _autoreleaseVec;
		static std::mutex _mutex;

		// pool of commands
		std::vector<cocos2d::TrianglesCommand*> _commandsPool;
		uint32_t _nextFreeCommand;

		// pool of vertices
		std::vector<cocos2d::V3F_C4B_T2F> _vertices;
		uint32_t _numVertices;

		// two color
		// pool of commands
		std::vector<TwoColorTrianglesCommand*> _twoColorCommandsPool;
		uint32_t _twoColorNextFreeCommand;

		// pool of vertices
		std::vector<V3F_C4B_C4B_T2F> _twoColorVertices;
		uint32_t _twoColorNumVertices;

		// pool of indices
		spUnsignedShortArray* _indices;

		// cache last command for asynchronous draw
		std::atomic_int _ref;
		std::vector<cocos2d::RenderCommand*> _lastCommands;
		std::size_t _threadID;
		SkeletonRenderer* _owner;
	};

    class SkeletonTwoColorBatch {
    public:
        static SkeletonTwoColorBatch* getInstance ();

        static void destroyInstance ();

        void update (float delta);

		TwoColorTrianglesCommand* addCommand(BatchThreadPool* pool, cocos2d::Renderer* renderer, float globalOrder, cocos2d::Texture2D* texture, cocos2d::GLProgramState* glProgramState, cocos2d::BlendFunc blendType, const TwoColorTriangles& triangles, const cocos2d::Mat4& mv, uint32_t flags);
		TwoColorTrianglesCommand* addCommandWithGroup(BatchThreadPool* pool, cocos2d::Renderer* renderer, int groupID, float globalOrder, cocos2d::Texture2D* texture, cocos2d::GLProgramState* glProgramState, cocos2d::BlendFunc blendType, const TwoColorTriangles& triangles, const cocos2d::Mat4& mv, uint32_t flags);
		TwoColorTrianglesCommand* addCommandInThread(BatchThreadPool* pool, cocos2d::Renderer* renderer, float globalOrder, cocos2d::Texture2D* texture, cocos2d::GLProgramState* glProgramState, cocos2d::BlendFunc blendType, const TwoColorTriangles& triangles, const cocos2d::Mat4& mv, uint32_t flags);

		cocos2d::GLProgramState* getTwoColorTintProgramState(cocos2d::Texture2D* texture);
		cocos2d::GLProgramState* getTwoColorTintProgramState(bool hadAlphaTex);
		
		void batch (TwoColorTrianglesCommand* command);
		
		void flush (TwoColorTrianglesCommand* materialCommand);
		
		uint32_t getNumBatches () { return _numBatches; };
		
    protected:
        SkeletonTwoColorBatch ();
        virtual ~SkeletonTwoColorBatch ();

		void reset ();

		
		// two color tint shader and state
		cocos2d::GLProgram* _twoColorTintShader;
		cocos2d::GLProgramState* _twoColorTintShaderState;

		cocos2d::GLProgram* _twoColorTintWithAlphaTexShader;
		cocos2d::GLProgramState* _twoColorTintWithAlphaTexShaderState;
		
		// VBO handles & attribute locations
		GLuint _vertexBufferHandle;
		V3F_C4B_C4B_T2F* _vertexBuffer;
		uint32_t _numVerticesBuffer;
		GLuint _indexBufferHandle;
		uint32_t _numIndicesBuffer;
		unsigned short* _indexBuffer;
		GLint _positionAttributeLocation;
		GLint _colorAttributeLocation;
		GLint _color2AttributeLocation;
		GLint _texCoordsAttributeLocation;
		GLint _alphaTexUniformLocation;
		
		// last batched command, needed for flushing to set material
		TwoColorTrianglesCommand* _lastCommand;
		
		// number of batches in the last frame
		uint32_t _numBatches;
	};
}

#endif // SPINE_SKELETONTWOCOLORBATCH_H_
