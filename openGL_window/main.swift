//
//  entry.swift
//  imageViewer
//
//  Created by Michael Kirschner on 1/16/20.
//  Copyright © 2020 Michael Kirschner. All rights reserved.
//

import Foundation
import AppKit
import MetalKit


final class TestApplicationController: NSObject, NSApplicationDelegate
{
    var win:NSWindow;
    var imageWidth:Int;
    var imageHeight:Int;
    var imageData: Array<uint8>;
    var pointer:UnsafeMutablePointer<uint8>;
    
    init(width:Int,height:Int) {
        win = NSWindow(contentRect: NSMakeRect(100, 100, CGFloat(width), CGFloat(height)),
                    styleMask: [.titled, .miniaturizable,.closable,.resizable],
                     backing: NSWindow.BackingStoreType.buffered, defer: true);
        imageWidth = width;
        imageHeight = height;
        
        print(imageWidth);
        print(imageHeight);
        //create some random data.
        //we assume we are writing RGBA colors
        //rgba8Unorm texture pix format width * height * 4 bytes per pixel.
        let start = DispatchTime.now() // <<<<<<<<<< Start time

        imageData = (0...imageWidth*imageHeight*4).map( {_ in UInt8.random(in: 0...255)} );
        imageData = (0...imageWidth*imageHeight*4).map({UInt8($0%255)});
        imageData = [UInt8]();
        imageData.reserveCapacity(imageWidth*imageHeight*4);
        let end = DispatchTime.now() // <<<<<<<<<< Start time
        
        print("took",Double(end.uptimeNanoseconds-start.uptimeNanoseconds)/1_000_000_000,"to generate random data");

        pointer = UnsafeMutablePointer(&imageData);

    }
    
    
     func applicationDidFinishLaunching(_ aNotification: Notification)
        {
             print("inside finish launch");
              win.makeKeyAndOrderFront(self);
            
            //TODO refactor into method create mtkView.
            let mtkView = MTKView();
               //TODO look this up.
               mtkView.translatesAutoresizingMaskIntoConstraints = false;
               //add to window.
               let view = win.contentView;
               view?.addSubview(mtkView);
               
            //TODO look this up.
            view!.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[mtkView]|", options: [], metrics: nil, views: ["mtkView" : mtkView]))
            view!.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[mtkView]|", options: [], metrics: nil, views: ["mtkView" : mtkView]))
            
            let device = MTLCreateSystemDefaultDevice()!
            mtkView.device = device;
            
            //instantiate our renderer - which will render images into the view:
            
            let tex2dRendererInstance = renderer(view: mtkView, width: imageWidth, height: imageHeight);
            mtkView.delegate = tex2dRendererInstance;
            
            //update the image fast.
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true)
            { timer in
                tex2dRendererInstance.UpdateTextureWithColorDataPointer(tex: tex2dRendererInstance.texture,pointer: self.pointer);
                print("inside timer");
            }
            
             print("makeKey window");
            
         
            }
            

        func applicationWillTerminate(_ aNotification: Notification) {
                // Insert code here to tear down your application
        }
    
    func updateTextureData(data:UnsafeMutablePointer<uint8>) {
        print("setting pointer to", data);
        pointer = data;
    }
}


var controller:TestApplicationController? = nil;

@_cdecl("start_render_view")
public func start_render_view(width:Int,height:Int){
    print("Hello, World - from swift!")
    let app = NSApplication.shared;
    controller =  TestApplicationController(width: width,height: height);
    app.delegate = controller;
     print("about to try running")
    app.run();
    
    print("GoodBye, World - from swift!");
}

@_cdecl("update_tex")
public func update_tex(data:UnsafeMutablePointer<uint8>){
    controller?.updateTextureData(data: data);
}


