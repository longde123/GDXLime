package com.gdx.scene3d.buffer ;

import com.gdx.gl.shaders.Shader;
import lime.graphics.opengl.GL;
import lime.graphics.opengl.GLBuffer;
import lime.graphics.opengl.GLProgram;
import lime.graphics.opengl.GLShader;
import lime.graphics.opengl.GLUniformLocation;
import lime.graphics.opengl.GLTexture;
import lime.graphics.RenderContext;
import lime.utils.Float32Array;
import lime.utils.Int16Array;


/**
 * ...
 * @author djoekr
 */
class VertexVBO
{
  	
	public var coordBuffer:GLBuffer;
	public var tex0Buffer:GLBuffer;
	public var tex1Buffer:GLBuffer;
	public var colBuffer:GLBuffer;
	public var normBuffer:GLBuffer;
	public var useDetail:Bool;
	public var useTexture:Bool;
	public var useColors:Bool;
	public var useNormals:Bool;
	public var pipeline:Shader;
	
	public function new(shader:Shader,texture0:Bool,texture1:Bool,colors:Bool,normals:Bool) 
	{
		this.pipeline = shader;
		

		if (shader.colorAttribute >= 0)
		{
			colors = true;
		} else
		{
			colors = false;
		}
		
		if (shader.normalAttribute >= 0)
		{
			normals = true;
		} else
		{
			normals = false;
		}
		normals = false;
		if (shader.texCoord0Attribute >= 0)
		{
			useTexture = true;
		} else
		{
			useTexture = false;
		}
		if (shader.texCoord1Attribute >= 0)
		{
			useDetail = true;
		} else
		{
			useDetail = false;
		}
			
		
				
		this.useTexture = texture0;
		this.useDetail = texture1;
		this.useColors = colors;
		this.useNormals = normals;
		
		coordBuffer = GL.createBuffer();
		
		if (useNormals)
		{
		normBuffer = GL.createBuffer();
	    }
		if (useTexture)
		{
		tex0Buffer = GL.createBuffer();
		if (useDetail)
		{
		tex1Buffer = GL.createBuffer();
		}
		}
	
		if (useColors)
		{
		colBuffer  = GL.createBuffer();
		}
		
		
		
		
	}
	
	public function uploadVertex(v:Array<Float>):Void
    {
		    GL.bindBuffer(GL.ARRAY_BUFFER, coordBuffer);
	        GL.bufferData(GL.ARRAY_BUFFER,  new Float32Array( v), GL.STATIC_DRAW);
			GL.bindBuffer(GL.ARRAY_BUFFER, null);
    }
	public function uploadNormals(v:Array<Float>):Void
    {
		   if (!useNormals) return;
		    GL.bindBuffer(GL.ARRAY_BUFFER, normBuffer);
	        GL.bufferData(GL.ARRAY_BUFFER,  new Float32Array( v), GL.STATIC_DRAW);
			GL.bindBuffer(GL.ARRAY_BUFFER, null);
    }
	public function uploadColors(v:Array<Float>):Void
    {
		   if (!useColors) return;
		    GL.bindBuffer(GL.ARRAY_BUFFER, colBuffer);
	        GL.bufferData(GL.ARRAY_BUFFER,  new Float32Array( v), GL.STATIC_DRAW);
			GL.bindBuffer(GL.ARRAY_BUFFER, null);
    }
	public function uploadUVCoord0(v:Array<Float>):Void
    {
		   if (!useTexture) return;
		    GL.bindBuffer(GL.ARRAY_BUFFER, tex0Buffer);
	        GL.bufferData(GL.ARRAY_BUFFER,  new Float32Array( v), GL.STATIC_DRAW);
			GL.bindBuffer(GL.ARRAY_BUFFER, null);
    }
	public function uploadUVCoord1(v:Array<Float>):Void
    {
		   if (!useTexture) return;
		   if (!useDetail) return;
		   
		    GL.bindBuffer(GL.ARRAY_BUFFER, tex1Buffer);
	        GL.bufferData(GL.ARRAY_BUFFER,  new Float32Array( v), GL.STATIC_DRAW);
			GL.bindBuffer(GL.ARRAY_BUFFER, null);
    }	
	
	public function bind():Void
	{
	
		GL.bindBuffer(GL.ARRAY_BUFFER, coordBuffer);
		GL.vertexAttribPointer(pipeline.vertexAttribute, 3, GL.FLOAT, false, 0, 0); 
    	GL.enableVertexAttribArray (pipeline.vertexAttribute);
	
		if (useNormals)
		{
			if (pipeline.normalAttribute != -1)
			{
		     GL.bindBuffer(GL.ARRAY_BUFFER, normBuffer);
		     GL.vertexAttribPointer(pipeline.normalAttribute, 3, GL.FLOAT, false, 0, 0); 
	         GL.enableVertexAttribArray (pipeline.normalAttribute);
			}
	    } 	else
		{
		 if(pipeline.normalAttribute!=-1) GL.disableVertexAttribArray (pipeline.normalAttribute);	
		}
		
		if (useTexture)
		{
			if (pipeline.texCoord0Attribute != -1)
			{
	         GL.bindBuffer(GL.ARRAY_BUFFER, tex0Buffer);
   	         GL.vertexAttribPointer(pipeline.texCoord0Attribute, 2, GL.FLOAT, false, 0, 0);  
		     GL.enableVertexAttribArray (pipeline.texCoord0Attribute);
			}
	     	if (useDetail)
		    {
				if (pipeline.texCoord1Attribute != -1)
				{
	             GL.bindBuffer(GL.ARRAY_BUFFER, tex1Buffer);
   	             GL.vertexAttribPointer(pipeline.texCoord1Attribute, 2, GL.FLOAT, false, 0, 0); 
		        GL.enableVertexAttribArray (pipeline.texCoord1Attribute);
				}
		    } else
		    {
		     if(pipeline.texCoord1Attribute!=-1) GL.disableVertexAttribArray (pipeline.texCoord1Attribute);
		    }
			
		} else
		{
			if(pipeline.texCoord0Attribute!=-1) GL.disableVertexAttribArray (pipeline.texCoord0Attribute);
			if(pipeline.texCoord1Attribute!=-1) GL.disableVertexAttribArray (pipeline.texCoord1Attribute);
		}
  
		if (useColors)
		{
			if (pipeline.colorAttribute != -1)
			{
	         GL.bindBuffer(GL.ARRAY_BUFFER, colBuffer);
   	         GL.vertexAttribPointer(pipeline.colorAttribute, 4, GL.FLOAT, false, 0, 0);  
	         GL.enableVertexAttribArray (pipeline.colorAttribute);
			}
		}	else
		{
		 if(pipeline.colorAttribute!=-1) GL.disableVertexAttribArray (pipeline.colorAttribute);	
		}
	    
		
		
		 
	}
	public function dispose()
	{
		GL.deleteBuffer(coordBuffer);
		
		
		if (useNormals)
		{
		GL.deleteBuffer(normBuffer );
	    }
		if (useTexture)
		{
		GL.deleteBuffer(tex0Buffer);
		if (useDetail)
		{
		GL.deleteBuffer(tex1Buffer);
		}
		}
	
		if (useColors)
		{
		GL.deleteBuffer(colBuffer);
		}
		
		
	}
}