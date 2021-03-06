package com.gdx.scene3d ;
/*
 Copyright (C) 2013-2014 Luis Santos AKA DJOKER
 
 This file is part of GDXLime .
 
 TrenchBroom is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 TrenchBroom is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with GDXLime.  If not, see <http://www.gnu.org/licenses/>.
 */
import lime.graphics.opengl.GL;
import com.gdx.color.Color4;
import com.gdx.gl.shaders.Brush;
import com.gdx.math.Matrix4;
import com.gdx.math.Quaternion;
import com.gdx.math.Vector2;
import com.gdx.math.Vector3;
import com.gdx.scene3d.animators.PosKeyFrame;
import com.gdx.scene3d.animators.RotKeyFrame;
import com.gdx.scene3d.B3DMesh.B3DBone;
import haxe.io.Path;
import lime.Assets;
import lime.utils.ByteArray;

class H3DKeyFrame
{
public var Pos:Vector3;
public var Rot:Quaternion;
public var time:Float;
public function new(t:Float,v:Vector3,r:Quaternion)
{
	Pos = v;
	time = t;
	Rot = r;
}
}

class H3DWight
{
	public var boneId:Int;
	public var Wight:Float;
		public function new(id:Int,w:Float) 
	    {
			boneId = id;
			Wight = w;
		}
}

class H3DVertex
{
	public var  Pos:Vector3;
	public var  bones:Array<H3DWight>;
	public var numBones:Int;

	
	public function new() 
	{
		Pos = Vector3.zero;
	    bones = [];
		bones.push(new H3DWight( -1, 0));
		bones.push(new H3DWight( -1, 0));
		bones.push(new H3DWight( -1, 0));
		bones.push(new H3DWight( -1, 0));
		numBones = 0;
	}
	public function sort():Void
	{
	
	bones.sort(function WightIndex(a:H3DWight, b:H3DWight):Int
    {

    if (a.Wight > b.Wight) return -1;
    if (a.Wight < b.Wight) return 1;
    return 0;
    } 
	);
	
	}
}

class H3DBone
{
  public var vertex:Array<H3DVertex>;
  public function new() 
	{
		vertex=[];
	}
}


class H3DJoint extends SceneNode
{
	  
     	public var Frames:Array<H3DKeyFrame>;
		
	    public  var offMatrix:Matrix4 = Matrix4.Identity(); 
		public var index:Int;
		public var numKeys:Int;
		public var parentName:String;
		


		public function new(scene:Scene,Parent:SceneNode,id:Int , name:String,pName:String)
	    {
		 super(scene, Parent, id, name);
		 parentName = pName;

		 Frames = [];
	
	 /*
	     var debug:Mesh = scene.addCube(this);
		  debug.MeshScale(0.8, 0.8, 0.8);
		  debug.getBrush(0).DiffuseColor.set(1, 0, 0);
	*/
		 index = 0;
	

		
		
		}
		
		public function initialize():Void
		{
		   		      UpdateAbsoluteTransformation();
					  LocalWorld.invertToRef(offMatrix);
		}
		
	private function FindKey(time:Float):Int
	{
		for (i in 0...Frames.length-1)
		{
			if (time < Frames[i + 1].time)
			{
				return i;
			}
		}
		return 0;
	}



	
	private function animate(movetime:Float):Void
	{
		
		    var currentIndex:Int = FindKey(movetime);
            var nextIndex:Int = (currentIndex + 1);
			
			if (nextIndex > Frames.length)
			{
				return;
			}  
				
			  var DeltaTime :Float= (Frames[nextIndex].time -Frames[currentIndex].time);
             var Factor = (movetime - Frames[currentIndex].time) / DeltaTime;
			 this.position = Vector3.Lerp(Frames[currentIndex].Pos, Frames[nextIndex].Pos, Factor);
			 rotate(Quaternion.Slerp(Frames[currentIndex].Rot, Frames[nextIndex].Rot, Factor));
			 
	}
	
	
	
		public function animateJoints(TimeInSeconds:Float):Void
		{
			
			animate(TimeInSeconds);
		    
		   
		   
		   UpdateAbsoluteTransformation();
		

		 var vector:Vector3 = Vector3.zero;
		 var parentvector:Vector3 = Vector3.zero;
		 
		 vector=AbsoluteTransformation.transformVector(vector);
		 
		 if (parent != null)
		 {
			parentvector = parent.AbsoluteTransformation.transformVector(parentvector);
			scene.lines.lineVector(vector, parentvector, 1, 0, 0, 1);
		 } else
		 {
			 scene.lines.lineVector(vector, vector, 1, 0, 0, 1);
		 }
		
 		}
}

class H3DMesh extends Mesh
{
	
private var  file:ByteArray;
private var  Bones:Array<H3DBone>;

private var textures:Array<String>;

private var brushes:Array<Brush> = new Array<Brush>();
private var texturepath:String;
private var isAnimated:Bool;

private var Joints:Array<H3DJoint>;

    public var NumFrames:Int;
    private var lastTime:Float;
	private var StartFrame:Int;
	private var EndFrame:Int;
	private var FramesPerSecond:Float;
	private var CurrentFrameNr:Float;
    private var LastTimeMs:Int;
	private	var Looping:Bool;
	private var CurrentTime:Float;
	

	public function new(scene:Scene,Parent:SceneNode = null , id:Int = 0, name:String="H3DMesh")  
	{
		 super(scene, Parent, id, name);
		
		 textures = [];
		 brushes = [];
		 Joints = [];
		 Bones = [];
    
		 FramesPerSecond = 0.025;
		 StartFrame = 0;
		 EndFrame = 0;
		 CurrentFrameNr = 0;
		 LastTimeMs = 0;
		 Looping = true;
		isAnimated = false;
		
		 NumFrames=0;
  
		 lastTime = Gdx.Instance().getTimer();

		
	}
	


	public  function load(filename:String,path:String):Void
	
	{
	if (!Assets.exists(filename))
			{
				trace("ERROR:Model " + filename+"dont exists..");
				return;
			}
			
		var file:ByteArray =	Assets.getBytes(filename);
	    	file.endian = "littleEndian";
        if (file.bytesAvailable <= 0) return;
	    file.position = 0;
		
		var  hSize:Int = file.readInt();
		var header:String = file.readUTFBytes(hSize);
		var id:Int = file.readInt();
		
		var numMaterials:Int = file.readInt();
		
		var brushes:Map<Int,Brush> = new Map<Int,Brush>();
		
		trace("Num materials :" + numMaterials);
		
		for (i in 0 ... numMaterials)
		{
			
			var  flags:Int = file.readInt();//
			var brush:Brush = new Brush(0);
			
			var r = file.readFloat();
			var g = file.readFloat();
			var b = file.readFloat();
			var alpha = file.readFloat();
			brush.DiffuseColor.set(r, g, b);
			brush.alpha = alpha;
			brush.materialId = i;
		//	trace('Color :' + brush.DiffuseColor.toString()+' alpha:'+alpha);
			
			var  nameSize:Int = file.readInt();
			if (nameSize >= 255) 
			{
				trace("ERROR:file dont match -"+nameSize+" color texture");
				return null;
			}
			var filename:String = file.readUTFBytes(nameSize);
			
			var  texture:String = Path.withoutDirectory(filename);
			if (Path.extension(texture) == 'bmp')
			{
				texture = Path.withoutExtension(texture);
				texture+= '.jpg';
			}else
			if (Path.extension(texture) == 'tga')
			{
				texture = Path.withoutExtension(texture);
				texture+= '.png';
			}
			
			if (Assets.exists(path  + texture))
			{
				
		 brush.setTexture( Gdx.Instance().getTexture(path  + texture, true));
			} else
			{
				trace("ERROR : dont find "+path  + texture+" color texture");
				
			}
			
			//****************
			
			//detail texture
			var  useDetail:Int = file.readInt();
			if (useDetail >= 1)
			{
			  var  nameSize:Int = file.readInt();
		  	var filename:String=file.readUTFBytes(nameSize);
			var  texture:String = Path.withoutDirectory(filename);
		    if (Path.extension(texture) == 'bmp')
			{
				texture = Path.withoutExtension(texture);
				texture+= '.jpg';
			}else
			if (Path.extension(texture) == 'tga')
			{
				texture = Path.withoutExtension(texture);
				texture+= '.png';
			}
			
				  
		     if (Assets.exists(path  + texture))
			{
		  brush.setDetail( Gdx.Instance().getTexture(path  + texture, true));
			} else
			{
				trace("ERROR : dont find"+path  + texture+" detail texture");
				
			}
			}
			
		
			brushes.set(i, brush);
	    }
		        var pos:Vector3 = new Vector3(0,0,0);
				var nor:Vector3 = new Vector3(0,0,0);
				var uv:Vector2 = new Vector2(0,0);
				var uv2:Vector2 = new Vector2(0,0);
				
				
				
		var  countMeshs:Int = file.readInt();
	///	trace("INFO:numsub surfaces:"+countMeshs);

	    for (i in 0 ... countMeshs)
		{

			var  nameSize:Int = file.readInt();//
			var name:String = file.readUTFBytes(nameSize);
		//	trace("sub mehs name:" + name);
			var  flags:Int = file.readInt();//
			var surf:Surface = createSurface();
			surf.materialIndex = file.readInt();
			var numVertices:Int=file.readInt();
			var numFaces:Int=file.readInt();
			var numUVCoords:Int = file.readInt();
	
		
			
			surf.brush.clone(brushes.get(surf.materialIndex));
			if (numUVCoords == 1)
			{
			surf.brush.setMaterialType(0);
			} else
			{
				surf.brush.setMaterialType(1);
			}
			 
			//
			
		//	trace("Mesh ["+i+"] , num Vertices["+numVertices+"],  num Faces["+numFaces+"],  num UVCoords["+numUVCoords+"], Material:["+surf.materialIndex+']' );
			var  BoneVertex:H3DBone = new H3DBone();
			
			for (x in 0...numVertices)
			{
			
				
				pos.x = file.readFloat();
				pos.y = file.readFloat();
				pos.z = file.readFloat();
				
				var vertex:H3DVertex = new H3DVertex();
				vertex.Pos.copyFrom(pos);
				
				BoneVertex.vertex.push(vertex);
				
				
				nor.x = file.readFloat();
				nor.y = file.readFloat();
				nor.z = file.readFloat();
			//	trace(nor.toString());
				uv.x = file.readFloat();
				uv.y =1*- file.readFloat();
				
		

			
			if (numUVCoords == 2)
			{
				   
					uv2.x = file.readFloat();
				    uv2.y =1*- file.readFloat();
					surf.AddFullVertex(pos.x, pos.y, pos.z, nor.x, nor.y, nor.z, uv.x, uv.y, uv2.x, uv2.y);
					//trace(uv.toString());
					//trace(uv2.toString());
			} else
			{
				//trace(uv.toString());
				surf.AddFullVertex(pos.x, pos.y, pos.z, nor.x, nor.y, nor.z, uv.x, uv.y, uv.x, uv.y);
			}
			
		//	trace(pos.toString());
			
		}
		Bones.push(BoneVertex);
			
			for (x in 0...numFaces)
			{
				var v0:Int = file.readInt();
				var v1:Int = file.readInt();
				var v2:Int = file.readInt();
	    		surf.AddTriangle(v0, v1, v2);
			}
		//if(loadtexture) surf.brush.setTexture(textures.get(surf.materialIndex));	
		 surf.updateBounding();	
         surf.UpdateVBO();
		//trace("Mesh ["+i+"] , num Vertices["+numVertices+"],  num Faces["+numFaces+"],  num UVCoords["+numUVCoords+"] , numColor["+numColors+"]" );
		}
		
		var numBones:Int = file.readInt();
		
	//	trace("Num of bones:"+numBones);
		
		if (numBones !=0)
		{
			 var framesPerSecond = file.readFloat();
			var duration = file.readFloat();
			if (framesPerSecond <= 0)
			{
				framesPerSecond = 1.0;
			}
			
			trace("Fps:" + framesPerSecond + " num frames:" + duration);
			setFrameLoop(0,Std.int(duration));
	        setAnimationSpeed(15);

	
			for (i in 0...numBones)
			{
			
			var  nameSize:Int = file.readInt();//
			var bname:String = file.readUTFBytes(nameSize);
			
		//	trace(nameSize+ " " + bname);
			
			var  parentnameSize:Int = file.readInt();//
			var parentname:String = file.readUTFBytes(parentnameSize);
			var Joint= new H3DJoint(scene, this, i, bname,parentname);
			var numKeys:Int = file.readInt();
			
			
		//	trace("Bone name:" + bname);
		//	trace("Bone parent name:" + parentname);
		//	trace("Num key Frames :" + numKeys);
			
			var Pos:Vector3 = Vector3.zero;
			var Rot:Quaternion = Quaternion.Zero();
			
			Pos.x = file.readFloat();
			Pos.y = file.readFloat();
			Pos.z = file.readFloat();
			Rot.x = file.readFloat();
			Rot.y = file.readFloat();
			Rot.z = file.readFloat();
			Rot.w = file.readFloat();
			
			Joint.position.copyFrom(Pos);
			Joint.rotate(Rot);
			Joint.numKeys = numKeys;
			
			
		

				for (i in 0...Joints.length)
			    {
					if ( Joints[i].name == parentname)
					{
						Joint.parent = Joints[i];
						Joint.initialize();
						break;
					}
		     	}
	
			
			
			for (x in 0...numKeys)
			{
				
			var Pos:Vector3 = Vector3.zero;
			var Rot:Quaternion = Quaternion.Zero();
			var time:Float=file.readFloat();
			Pos.x = file.readFloat();
			Pos.y = file.readFloat();
			Pos.z = file.readFloat();
			Rot.x = file.readFloat();
			Rot.y = file.readFloat();
			Rot.z = file.readFloat();
			Rot.w = file.readFloat();
			
			//trace("time:"+time);
			
			Joint.Frames.push(new H3DKeyFrame(time,Pos, Rot));
			
			
			 
			
			}
			
		
			
			 Joints.push(Joint);
			}
			
			
			
			for (i in 0...CountSurfaces())
			{
			  var  numJoints:Int = file.readInt();//
			  for (x in 0...numJoints)
			 {
				 			var  nameSize:Int = file.readInt();//
		         	        var  name:String = file.readUTFBytes(nameSize);
							var  NumWeights:Int = file.readInt();//
							
						//	trace("Join name:" + name + " bones:" + NumWeights);
							
							var jointId:Int = getJointIndex(name);
							
	
							
		     for (j in 0...NumWeights)
			 {
				 var vertexId:Int = file.readInt();//
				 var Weight:Float = file.readFloat();//
				 
				//  trace( " name :" + name +" Index :" + jointId);
				  
				 for (count in 0...4)
	             {
					 if (Bones[i].vertex[vertexId].bones[count].boneId == -1)
					 {
						// trace("Vertex have :"+jointId+" name :"+name );
						 
						 
						 if (Weight < 0.001)  Weight = 0.0;
				         if (Weight > 0.999)  Weight = 1.0;
				         Bones[i].vertex[vertexId].bones[count].Wight = Weight;
						 Bones[i].vertex[vertexId].bones[count].boneId = jointId;
						 Bones[i].vertex[vertexId].numBones++;
						 
					//	 trace( " name :" + name +"count :"+Bones[i].vertex[vertexId].numBones);
						 break;
					 }
	             }
				 
				Bones[i].vertex[vertexId].sort();
				 
			 }
			 
			 
			
			}
			
			}//
		
		}
			
		
		UpdateBoundingBox();
		sortMaterial();
	  /*
		for (b in 0... Bones.length)
		{
			for (v in 0... Bones[b].vertex.length)
			{
				for (i in 0... Bones[b].vertex[v].numBones)
				{
				trace("bone id:" +	Bones[b].vertex[v].bones[i].boneId + " force: " + Bones[b].vertex[v].bones[i].Wight);
				}
			}
		}
    */
	
		brushes = null;
	}

public function getJoint(name:String):H3DJoint
{
	for (i in 0...Joints.length)
	{
		if (Joints[i].name == name)
		{
			return Joints[i];
		}
	}
	return null;
}
public function getJointIndex(name:String):Int
{
	for (i in 0...Joints.length)
	{
		if (Joints[i].name == name)
		{
			return i;
		}
	}
	return -1;
}	
public function getAnimationSpeed():Float
{
	return FramesPerSecond * 1000.0;
}
public function getFrameNr():Int
{
	return Std.int(CurrentFrameNr);
}

	
	
  private function OnAnimate(timeMs:Int):Void
  {
	
	  if (LastTimeMs==0)	// first frame
	{
		LastTimeMs = timeMs;
	}
	
	buildFrameNr(timeMs - LastTimeMs);
	

	
	
	    for (i in 0... Joints.length)
		{
			var Joint:H3DJoint = Joints[i];
			Joint.animateJoints(CurrentFrameNr);
		}

	
		for ( s in 0...surfaces.length)
		{
		
		var surf:Surface = surfaces[s];
		
		var Bone = Bones[s];
		
		
		
		for (i in 0...Bone.vertex.length)
		{
			
			
		   var vertex:H3DVertex = Bone.vertex[i];
		   
		var x:Float = 0;
		var y:Float = 0;
		var z:Float = 0;
		var ovx:Float = 0;
		var ovy:Float = 0;
		var ovz:Float = 0;
		
		   if (vertex.bones[0].boneId != -1)
		   {
			  var pos:Vector3 = vertex.Pos;
	
			  
			  var tform_mat:Matrix4 =Matrix4.multiplyWith( Joints[vertex.bones[0].boneId].AbsoluteTransformation,Joints[vertex.bones[0].boneId].offMatrix);
			  
			  var w:Float = vertex.bones[0].Wight;
		
		      
			  ovx=pos.x;
              ovy=pos.y;
              ovz=pos.z;
            
			   x = ( tform_mat.m[0] * ovx + tform_mat.m[4] * ovy + tform_mat.m[8] * ovz  + tform_mat.m[12] ) * w;
			   y = ( tform_mat.m[1] * ovx + tform_mat.m[5] * ovy + tform_mat.m[9] * ovz  + tform_mat.m[13] ) * w;
		 	   z = ( tform_mat.m[2] * ovx + tform_mat.m[6] * ovy + tform_mat.m[10] * ovz + tform_mat.m[14] ) * w;
		
			
			  if (vertex.bones[1].boneId != -1)
		      {
			    var tform_mat:Matrix4 =Matrix4.multiplyWith( Joints[vertex.bones[1].boneId].AbsoluteTransformation,Joints[vertex.bones[1].boneId].offMatrix);
			
			   var w:Float = vertex.bones[1].Wight;
		       x =x+ ( tform_mat.m[0] * ovx + tform_mat.m[4] * ovy + tform_mat.m[8] * ovz  + tform_mat.m[12] ) * w;
			   y =y+ ( tform_mat.m[1] * ovx + tform_mat.m[5] * ovy + tform_mat.m[9] * ovz  + tform_mat.m[13] ) * w;
		 	   z =z+ ( tform_mat.m[2] * ovx + tform_mat.m[6] * ovy + tform_mat.m[10] * ovz + tform_mat.m[14] ) * w;
		
			   
			  if (vertex.bones[2].boneId != -1)
		      {
		    	var tform_mat:Matrix4 =Matrix4.multiplyWith( Joints[vertex.bones[2].boneId].AbsoluteTransformation,Joints[vertex.bones[2].boneId].offMatrix);
			
			    var w:Float = vertex.bones[2].Wight;
		       x =x+ ( tform_mat.m[0] * ovx + tform_mat.m[4] * ovy + tform_mat.m[8] * ovz  + tform_mat.m[12] ) * w;
			   y =y+ ( tform_mat.m[1] * ovx + tform_mat.m[5] * ovy + tform_mat.m[9] * ovz  + tform_mat.m[13] ) * w;
		 	   z =z+ ( tform_mat.m[2] * ovx + tform_mat.m[6] * ovy + tform_mat.m[10] * ovz + tform_mat.m[14] ) * w;
		
			   
			   if (vertex.bones[3].boneId != -1)
		      {
		   	  var tform_mat:Matrix4 =Matrix4.multiplyWith( Joints[vertex.bones[3].boneId].AbsoluteTransformation,Joints[vertex.bones[3].boneId].offMatrix);
			   var w:Float = vertex.bones[3].Wight;
		       x =x+ ( tform_mat.m[0] * ovx + tform_mat.m[4] * ovy + tform_mat.m[8] * ovz  + tform_mat.m[12] ) * w;
			   y =y+ ( tform_mat.m[1] * ovx + tform_mat.m[5] * ovy + tform_mat.m[9] * ovz  + tform_mat.m[13] ) * w;
		 	   z =z+ ( tform_mat.m[2] * ovx + tform_mat.m[6] * ovy + tform_mat.m[10] * ovz + tform_mat.m[14] ) * w;
		
		      }
			  
		      }
			 
		     }
			
		    }
		  
			
	
				

		surf.VertexCoords(i, x, y, z);
		}
		}

	
	LastTimeMs = timeMs;
  }
  
  public function setCurrentFrame( frame:Float):Void
{
	// if you pass an out of range value, we just clamp it
	CurrentFrameNr =Util.clamp( frame, StartFrame, EndFrame );

}

public function setFrameLoop( begin:Int, end:Int, loop:Bool = true ):Void
{
	Looping = loop;
	StartFrame = begin;
	EndFrame = end;

	
}


//! sets the speed with witch the animation is played
public function setAnimationSpeed( framesPerSecond:Float):Void
{
	FramesPerSecond = framesPerSecond * 0.001;
}

private function   buildFrameNr( timeMs:Int)
{
	
	
		CurrentFrameNr += timeMs * FramesPerSecond;

			if (CurrentFrameNr > EndFrame)
			{
				CurrentFrameNr =  StartFrame + Util.fMod( CurrentFrameNr - StartFrame , (EndFrame-StartFrame));
			}
		
	
}

  

override public function render(camera:Camera) 
	{

		if (!Visible) return;
	    var meshTrasform:Matrix4 = getAbsoluteTransformation();
		
	
	
    	var scaleFactor:Float = Math.max(scaling.x, scaling.y);
             scaleFactor = Math.max(scaleFactor,scaling.z);
		Gdx.Instance().numMesh++;
	     scene.shader.setWorldMatrix(meshTrasform);
	
	  
	  	
		   

    	for (i in 0... surfaces.length)
		{
			
			  scene.setMaterial(surfaces[i].brush);
			//  surfaces[i].primitiveType = GL.LINE_LOOP;
		     surfaces[i].render();
			  
		}
		

	}
	
    override public function update():Void
	{
		super.update();     
	   OnAnimate(Gdx.Instance().getTimer());
	}
}