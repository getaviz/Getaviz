/** X3DOM Runtime, http://www.x3dom.org/ 1.6.2 - 8f5655cec1951042e852ee9def292c9e0194186b - Sat Dec 20 00:03:52 2014 +0100 */
x3dom.registerNodeType("ScreenGroup","Layout",defineClass(x3dom.nodeTypes.X3DGroupingNode,function(ctx){x3dom.nodeTypes.ScreenGroup.superClass.call(this,ctx);},{collectDrawableObjects:function(transform,drawableCollection,singlePath,invalidateCache,planeMask,clipPlanes)
{if(singlePath&&(this._parentNodes.length>1))
singlePath=false;if(singlePath&&(invalidateCache=invalidateCache||this.cacheInvalid()))
this.invalidateCache();planeMask=drawableCollection.cull(transform,this.graphState(),singlePath,planeMask);if(planeMask<=0){return;}
singlePath=false;var doc,vp,minus_one,zero,viewport_height,one_to_one_pixel_depth,view_transform,view_direction,model_transform,camera_position,screengroup_position,viewpoint_to_screengroup,ratio,scale_matrix;doc=this._nameSpace.doc;vp=doc._scene.getViewpoint();viewport_height=doc._x3dElem.clientHeight;one_to_one_pixel_depth=viewport_height/vp.getImgPlaneHeightAtDistOne();minus_one=new x3dom.fields.SFVec3f(0,0,-1.0);zero=new x3dom.fields.SFVec3f(0,0,0);view_transform=drawableCollection.viewMatrix;model_transform=transform;view_direction=minus_one;camera_position=zero;screengroup_position=view_transform.multMatrixPnt(model_transform.multMatrixPnt(zero));viewpoint_to_screengroup=screengroup_position.subtract(camera_position);ratio=view_direction.dot(viewpoint_to_screengroup)/one_to_one_pixel_depth;scale_matrix=x3dom.fields.SFMatrix4f.scale(new x3dom.fields.SFVec3f(ratio,ratio,ratio));var childTransform=this.transformMatrix(model_transform.mult(scale_matrix));for(var i=0,i_n=this._childNodes.length;i<i_n;i++)
{var cnode=this._childNodes[i];if(cnode){cnode.collectDrawableObjects(childTransform,drawableCollection,singlePath,invalidateCache,planeMask,clipPlanes);}}}}));