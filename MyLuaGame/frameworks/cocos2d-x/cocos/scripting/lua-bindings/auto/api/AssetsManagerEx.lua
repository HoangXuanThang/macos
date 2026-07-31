
--------------------------------
-- @module AssetsManagerEx
-- @extend Ref
-- @parent_module cc

--------------------------------
--  @brief Gets the current update state.
-- @function [parent=#AssetsManagerEx] getState 
-- @param self
-- @return int#int ret (return value: int)
        
--------------------------------
-- 
-- @function [parent=#AssetsManagerEx] getPatchMinVersion 
-- @param self
-- @return int#int ret (return value: int)
        
--------------------------------
--  @brief Function for retrieving the max concurrent task count
-- @function [parent=#AssetsManagerEx] getMaxConcurrentTask 
-- @param self
-- @return int#int ret (return value: int)
        
--------------------------------
--  @brief Set the handle function for comparing manifests versions<br>
-- param handle    The compare function
-- @function [parent=#AssetsManagerEx] setVersionCompareHandle 
-- @param self
-- @param #function handle
-- @return AssetsManagerEx#AssetsManagerEx self (return value: cc.AssetsManagerEx)
        
--------------------------------
--  @brief Set the verification function for checking whether downloaded asset is correct, e.g. using md5 verification<br>
-- param callback  The verify callback function
-- @function [parent=#AssetsManagerEx] setVerifyCallback 
-- @param self
-- @param #function callback
-- @return AssetsManagerEx#AssetsManagerEx self (return value: cc.AssetsManagerEx)
        
--------------------------------
--  @brief Gets storage path.
-- @function [parent=#AssetsManagerEx] getStoragePath 
-- @param self
-- @return string#string ret (return value: string)
        
--------------------------------
--  @brief Update with the current local manifest.
-- @function [parent=#AssetsManagerEx] update 
-- @param self
-- @return AssetsManagerEx#AssetsManagerEx self (return value: cc.AssetsManagerEx)
        
--------------------------------
-- 
-- @function [parent=#AssetsManagerEx] setLocalSearchPath 
-- @param self
-- @param #bool inMain
-- @return AssetsManagerEx#AssetsManagerEx self (return value: cc.AssetsManagerEx)
        
--------------------------------
-- 
-- @function [parent=#AssetsManagerEx] getPatchVersion 
-- @param self
-- @return int#int ret (return value: int)
        
--------------------------------
--  @brief Function for setting the max concurrent task count
-- @function [parent=#AssetsManagerEx] setMaxConcurrentTask 
-- @param self
-- @param #int max
-- @return AssetsManagerEx#AssetsManagerEx self (return value: cc.AssetsManagerEx)
        
--------------------------------
--  @brief Function for retrieving the remote manifest object
-- @function [parent=#AssetsManagerEx] getRemoteManifest 
-- @param self
-- @return Manifest#Manifest ret (return value: cc.Manifest)
        
--------------------------------
-- 
-- @function [parent=#AssetsManagerEx] onLuaSuccess 
-- @param self
-- @return AssetsManagerEx#AssetsManagerEx self (return value: cc.AssetsManagerEx)
        
--------------------------------
--  @brief Reupdate all failed assets under the current AssetsManagerEx context
-- @function [parent=#AssetsManagerEx] downloadFailedAssets 
-- @param self
-- @return AssetsManagerEx#AssetsManagerEx self (return value: cc.AssetsManagerEx)
        
--------------------------------
-- 
-- @function [parent=#AssetsManagerEx] getInstance 
-- @param self
-- @return AssetsManagerEx#AssetsManagerEx ret (return value: cc.AssetsManagerEx)
        
--------------------------------
-- 
-- @function [parent=#AssetsManagerEx] AssetsManagerEx 
-- @param self
-- @param #string storagePath
-- @return AssetsManagerEx#AssetsManagerEx self (return value: cc.AssetsManagerEx)
        
return nil
