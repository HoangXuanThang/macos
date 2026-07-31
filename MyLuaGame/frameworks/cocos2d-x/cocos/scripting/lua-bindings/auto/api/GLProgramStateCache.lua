
--------------------------------
-- @module GLProgramStateCache
-- @parent_module cc

--------------------------------
-- Remove unused GLProgramState.
-- @function [parent=#GLProgramStateCache] removeUnusedGLProgramState 
-- @param self
-- @return GLProgramStateCache#GLProgramStateCache self (return value: cc.GLProgramStateCache)
        
--------------------------------
-- Remove all the cached GLProgramState.
-- @function [parent=#GLProgramStateCache] removeAllGLProgramState 
-- @param self
-- @return GLProgramStateCache#GLProgramStateCache self (return value: cc.GLProgramStateCache)
        
--------------------------------
-- Get the shared GLProgramState by the owner GLProgram.
-- @function [parent=#GLProgramStateCache] getGLProgramState 
-- @param self
-- @param #cc.GLProgram program
-- @return GLProgramState#GLProgramState ret (return value: cc.GLProgramState)
        
--------------------------------
-- Destroy the GLProgramStateCache singleton.
-- @function [parent=#GLProgramStateCache] destroyInstance 
-- @param self
-- @return GLProgramStateCache#GLProgramStateCache self (return value: cc.GLProgramStateCache)
        
--------------------------------
-- Get the GLProgramStateCache singleton instance.
-- @function [parent=#GLProgramStateCache] getInstance 
-- @param self
-- @return GLProgramStateCache#GLProgramStateCache ret (return value: cc.GLProgramStateCache)
        
return nil
