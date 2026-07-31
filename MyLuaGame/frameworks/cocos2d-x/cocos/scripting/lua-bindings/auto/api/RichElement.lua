
--------------------------------
-- @module RichElement
-- @extend Ref
-- @parent_module ccui

--------------------------------
-- 
-- @function [parent=#RichElement] setAnchorPoint 
-- @param self
-- @param #vec2_table anchor
-- @return RichElement#RichElement self (return value: ccui.RichElement)
        
--------------------------------
-- 
-- @function [parent=#RichElement] setColor 
-- @param self
-- @param #color4b_table color
-- @return RichElement#RichElement self (return value: ccui.RichElement)
        
--------------------------------
-- 
-- @function [parent=#RichElement] setUrl 
-- @param self
-- @param #string url
-- @return RichElement#RichElement self (return value: ccui.RichElement)
        
--------------------------------
-- brief Initialize a rich element with different arguments.<br>
-- param tag A integer tag value.<br>
-- param color A color in @see `Color3B`.<br>
-- param opacity A opacity value in `GLubyte`.<br>
-- return True if initialize success, false otherwise.
-- @function [parent=#RichElement] init 
-- @param self
-- @param #int tag
-- @param #color4b_table color
-- @param #unsigned char opacity
-- @param #string url
-- @param #vec2_table anchor
-- @return bool#bool ret (return value: bool)
        
--------------------------------
-- 
-- @function [parent=#RichElement] equalType 
-- @param self
-- @param #int type
-- @return bool#bool ret (return value: bool)
        
--------------------------------
-- brief Default constructor.<br>
-- js ctor<br>
-- lua new
-- @function [parent=#RichElement] RichElement 
-- @param self
-- @return RichElement#RichElement self (return value: ccui.RichElement)
        
return nil
