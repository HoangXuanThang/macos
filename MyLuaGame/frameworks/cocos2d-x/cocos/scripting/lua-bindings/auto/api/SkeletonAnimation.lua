
--------------------------------
-- @module SkeletonAnimation
-- @extend SkeletonRenderer
-- @parent_module sp

--------------------------------
-- 
-- @function [parent=#SkeletonAnimation] setTrackCompleteListener 
-- @param self
-- @param #spTrackEntry entry
-- @param #function listener
-- @return SkeletonAnimation#SkeletonAnimation self (return value: sp.SkeletonAnimation)
        
--------------------------------
-- 
-- @function [parent=#SkeletonAnimation] getBoneScaleY 
-- @param self
-- @param #char boneName
-- @return float#float ret (return value: float)
        
--------------------------------
-- 
-- @function [parent=#SkeletonAnimation] findAnimation 
-- @param self
-- @param #string name
-- @return spAnimation#spAnimation ret (return value: spAnimation)
        
--------------------------------
-- 
-- @function [parent=#SkeletonAnimation] setCompleteListener 
-- @param self
-- @param #function listener
-- @return SkeletonAnimation#SkeletonAnimation self (return value: sp.SkeletonAnimation)
        
--------------------------------
-- 
-- @function [parent=#SkeletonAnimation] setMix 
-- @param self
-- @param #string fromAnimation
-- @param #string toAnimation
-- @param #float duration
-- @return SkeletonAnimation#SkeletonAnimation self (return value: sp.SkeletonAnimation)
        
--------------------------------
-- 
-- @function [parent=#SkeletonAnimation] setTrackStartListener 
-- @param self
-- @param #spTrackEntry entry
-- @param #function listener
-- @return SkeletonAnimation#SkeletonAnimation self (return value: sp.SkeletonAnimation)
        
--------------------------------
-- 
-- @function [parent=#SkeletonAnimation] addEmptyAnimation 
-- @param self
-- @param #int trackIndex
-- @param #float mixDuration
-- @param #float delay
-- @return spTrackEntry#spTrackEntry ret (return value: spTrackEntry)
        
--------------------------------
-- 
-- @function [parent=#SkeletonAnimation] setDisposeListener 
-- @param self
-- @param #function listener
-- @return SkeletonAnimation#SkeletonAnimation self (return value: sp.SkeletonAnimation)
        
--------------------------------
-- 
-- @function [parent=#SkeletonAnimation] setTrackInterruptListener 
-- @param self
-- @param #spTrackEntry entry
-- @param #function listener
-- @return SkeletonAnimation#SkeletonAnimation self (return value: sp.SkeletonAnimation)
        
--------------------------------
-- 
-- @function [parent=#SkeletonAnimation] setEndListener 
-- @param self
-- @param #function listener
-- @return SkeletonAnimation#SkeletonAnimation self (return value: sp.SkeletonAnimation)
        
--------------------------------
-- 
-- @function [parent=#SkeletonAnimation] getBoneRotation 
-- @param self
-- @param #char boneName
-- @return float#float ret (return value: float)
        
--------------------------------
-- 
-- @function [parent=#SkeletonAnimation] setTrackDisposeListener 
-- @param self
-- @param #spTrackEntry entry
-- @param #function listener
-- @return SkeletonAnimation#SkeletonAnimation self (return value: sp.SkeletonAnimation)
        
--------------------------------
-- 
-- @function [parent=#SkeletonAnimation] setEventListener 
-- @param self
-- @param #function listener
-- @return SkeletonAnimation#SkeletonAnimation self (return value: sp.SkeletonAnimation)
        
--------------------------------
-- 
-- @function [parent=#SkeletonAnimation] setEmptyAnimation 
-- @param self
-- @param #int trackIndex
-- @param #float mixDuration
-- @return spTrackEntry#spTrackEntry ret (return value: spTrackEntry)
        
--------------------------------
-- 
-- @function [parent=#SkeletonAnimation] setTrackEventListener 
-- @param self
-- @param #spTrackEntry entry
-- @param #function listener
-- @return SkeletonAnimation#SkeletonAnimation self (return value: sp.SkeletonAnimation)
        
--------------------------------
-- 
-- @function [parent=#SkeletonAnimation] clearTrack 
-- @param self
-- @return SkeletonAnimation#SkeletonAnimation self (return value: sp.SkeletonAnimation)
        
--------------------------------
-- 
-- @function [parent=#SkeletonAnimation] setInterruptListener 
-- @param self
-- @param #function listener
-- @return SkeletonAnimation#SkeletonAnimation self (return value: sp.SkeletonAnimation)
        
--------------------------------
-- 
-- @function [parent=#SkeletonAnimation] getBonePosition 
-- @param self
-- @param #char boneName
-- @return vec2_table#vec2_table ret (return value: vec2_table)
        
--------------------------------
-- 
-- @function [parent=#SkeletonAnimation] setEmptyAnimations 
-- @param self
-- @param #float mixDuration
-- @return SkeletonAnimation#SkeletonAnimation self (return value: sp.SkeletonAnimation)
        
--------------------------------
-- 
-- @function [parent=#SkeletonAnimation] getBoneShearX 
-- @param self
-- @param #char boneName
-- @return float#float ret (return value: float)
        
--------------------------------
-- 
-- @function [parent=#SkeletonAnimation] getBoneShearY 
-- @param self
-- @param #char boneName
-- @return float#float ret (return value: float)
        
--------------------------------
-- 
-- @function [parent=#SkeletonAnimation] clearTracks 
-- @param self
-- @return SkeletonAnimation#SkeletonAnimation self (return value: sp.SkeletonAnimation)
        
--------------------------------
-- 
-- @function [parent=#SkeletonAnimation] getBoneScaleX 
-- @param self
-- @param #char boneName
-- @return float#float ret (return value: float)
        
--------------------------------
-- 
-- @function [parent=#SkeletonAnimation] setTrackEndListener 
-- @param self
-- @param #spTrackEntry entry
-- @param #function listener
-- @return SkeletonAnimation#SkeletonAnimation self (return value: sp.SkeletonAnimation)
        
--------------------------------
-- 
-- @function [parent=#SkeletonAnimation] setStartListener 
-- @param self
-- @param #function listener
-- @return SkeletonAnimation#SkeletonAnimation self (return value: sp.SkeletonAnimation)
        
--------------------------------
-- 
-- @function [parent=#SkeletonAnimation] getBoneRotationX 
-- @param self
-- @param #char boneName
-- @return float#float ret (return value: float)
        
--------------------------------
-- 
-- @function [parent=#SkeletonAnimation] getBoneRotationY 
-- @param self
-- @param #char boneName
-- @return float#float ret (return value: float)
        
--------------------------------
-- @overload self, string, string, float         
-- @overload self, string, spAtlas, float         
-- @function [parent=#SkeletonAnimation] createWithBinaryFile
-- @param self
-- @param #string skeletonBinaryFile
-- @param #spAtlas atlas
-- @param #float scale
-- @return SkeletonAnimation#SkeletonAnimation ret (return value: sp.SkeletonAnimation)

--------------------------------
-- 
-- @function [parent=#SkeletonAnimation] create 
-- @param self
-- @return SkeletonAnimation#SkeletonAnimation ret (return value: sp.SkeletonAnimation)
        
--------------------------------
-- @overload self, string, string, float         
-- @overload self, string, spAtlas, float         
-- @function [parent=#SkeletonAnimation] createWithJsonFile
-- @param self
-- @param #string skeletonJsonFile
-- @param #spAtlas atlas
-- @param #float scale
-- @return SkeletonAnimation#SkeletonAnimation ret (return value: sp.SkeletonAnimation)

--------------------------------
-- 
-- @function [parent=#SkeletonAnimation] initialize 
-- @param self
-- @return SkeletonAnimation#SkeletonAnimation self (return value: sp.SkeletonAnimation)
        
return nil
