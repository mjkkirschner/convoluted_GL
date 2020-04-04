//
//  renderer.swift
//  imageViewer
//
//modified from BasicTexturing sample.

//

import Foundation;
import Metal;
import simd;
import MetalKit;

class renderer: NSObject,MTKViewDelegate {
   
    var device:MTLDevice;
    var pipelineState:MTLRenderPipelineState?;
    var commandQ:MTLCommandQueue;
    public var texture:MTLTexture;
    var planeVerts:MTLBuffer;
    var vertNum:Int;
    var viewPortSize:vector_uint2?;
    var scaleFac:Float;
    
    public init(view:MTKView,width:Int, height:Int){
                
        device = view.device!;
        texture = renderer.CreateMetalTexture(width: width,height: height);
        viewPortSize = vector_uint2(UInt32(width), UInt32(height));
        scaleFac = Float(view.window!.backingScaleFactor);
        let fw = Float(width) ;
        let fh = Float(height);
        let quadVertices =
               // Pixel positions, Texture coordinates
           [
            AAPLVertex(position:vector_float2(1.0*fw,-1.0*fh),textureCoordinate:vector_float2(1.0, 1.0)),
            AAPLVertex(position:vector_float2(-1.0*fw,-1.0*fh),textureCoordinate:vector_float2(0.0, 1.0)),
            AAPLVertex(position:vector_float2(-1.0*fw,1.0*fh),textureCoordinate:vector_float2(0.0, 0.0)),
               
            AAPLVertex(position:vector_float2(1.0*fw,-1.0*fh),textureCoordinate:vector_float2(1.0, 1.0)),
            AAPLVertex(position:vector_float2(-1.0*fw,1.0*fh),textureCoordinate:vector_float2(0.0, 0.0)),
            AAPLVertex(position:vector_float2(1.0*fw,1.0*fh),textureCoordinate:vector_float2(1.0, 0.0)),
               
           ];
        
        // Create a vertex buffer, and initialize it with the quadVertices array
        planeVerts = device.makeBuffer(bytes: quadVertices,length: quadVertices.count * MemoryLayout<AAPLVertex>.stride,options: MTLResourceOptions.storageModeShared)!;
        // Calculate the number of vertices by dividing the byte length by the size of each vertex

        vertNum = quadVertices.count * MemoryLayout<AAPLVertex>.stride /  MemoryLayout<AAPLVertex>.size;
        print (vertNum);
        /// Create the render pipeline.
        print("about to try to access device");
         print(device);
        
        print(Bundle.main);
        
        // Load the shaders from the bundled library
        let frameworkBundle = Bundle(for: renderer.self)
        
        guard let defaultLibrary = try? device.makeDefaultLibrary(bundle: frameworkBundle) else{
            fatalError("Could not load default library from specified bundle")

        }
        print(defaultLibrary);
        let vertexFunction = defaultLibrary.makeFunction(name: "vertexShader");
        let fragmentFunction = defaultLibrary.makeFunction(name: "samplingShader");
        
         // Set up a descriptor for creating a pipeline state object
        let pipelinestatedescriptor = MTLRenderPipelineDescriptor();
        pipelinestatedescriptor.label = "Texturing Pipeline";
        pipelinestatedescriptor.vertexFunction = vertexFunction;
        pipelinestatedescriptor.fragmentFunction = fragmentFunction;
        pipelinestatedescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat;
        
        
        do{
        try pipelineState = device.makeRenderPipelineState(descriptor: pipelinestatedescriptor);
        }
        catch{
            print(error);
        
        }
        commandQ = device.makeCommandQueue()!;
                
    }
    
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
        viewPortSize!.x = UInt32(size.width);
        viewPortSize!.y = UInt32(size.height);
        scaleFac = Float(view.window!.backingScaleFactor);

        
       }
       
    func draw(in view: MTKView) {
          // Create a new command buffer for each render pass to the current drawable
        
        let commandBuffer = commandQ.makeCommandBuffer();
        commandBuffer?.label = "MyCommand";
        

               // Obtain a renderPassDescriptor generated from the view's drawable textures
        
        let renderPassDescriptor = view.currentRenderPassDescriptor;
        if(renderPassDescriptor != nil){
            let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor!);
            renderEncoder!.label? = "MyRenderEncoder";
            renderEncoder!.setViewport(MTLViewport(originX: 0.0, originY: 0.0, width: Double(viewPortSize!.x), height: Double(viewPortSize!.y), znear: -1.0, zfar: 1.0));
            renderEncoder!.setRenderPipelineState(pipelineState!);
            renderEncoder!.setVertexBuffer(planeVerts, offset: 0, index: Int(AAPLVertexInputIndexVertices.rawValue));
            renderEncoder!.setVertexBytes(&viewPortSize, length: MemoryLayout.size(ofValue: viewPortSize), index: Int(AAPLVertexInputIndexViewportSize.rawValue));
            
           
            renderEncoder!.setVertexBytes( UnsafePointer<Float>(&scaleFac), length:MemoryLayout<Float>.size, index: 2);
            
            // Set the texture object.  The AAPLTextureIndexBaseColor enum value corresponds
                              ///  to the 'colorMap' argument in the 'samplingShader' function because its
                              //   texture attribute qualifier also uses AAPLTextureIndexBaseColor for its index.
            renderEncoder?.setFragmentTexture(texture, index:Int(AAPLTextureIndexBaseColor.rawValue));
               // Draw the triangles.
            renderEncoder?.drawPrimitives(type: MTLPrimitiveType.triangle, vertexStart:0, vertexCount:vertNum);
            
            renderEncoder?.endEncoding();
            // Schedule a present once the framebuffer is complete using the current drawable

            commandBuffer?.present(view.currentDrawable!);
          
        }
        
        // Finalize rendering here & push the command buffer to the GPU

                  commandBuffer?.commit();
           }
    

    public static func  CreateMetalTexture(width:Int, height:Int)->MTLTexture{
        let descriptor = MTLTextureDescriptor();
        descriptor.pixelFormat = MTLPixelFormat.rgba8Unorm;
        descriptor.width = width;
        descriptor.height = height;
        
        let texture = MTLCreateSystemDefaultDevice()!.makeTexture(descriptor: descriptor);
        return texture!;
    }

   public func UpdateTextureWithColorDataPointer(tex:MTLTexture,pointer:UnsafeMutablePointer< UInt8 >){
        //the entire texture is to be updated...
        let region:MTLRegion = MTLRegion(origin: MTLOrigin(x: 0, y: 0, z: 0), size: MTLSize(width: tex.width, height: tex.height, depth: 1));
        let bytesPerRow = 4*tex.width;
        tex.replace(region: region, mipmapLevel: 0, withBytes: pointer, bytesPerRow: bytesPerRow);
    }

   
    
}
