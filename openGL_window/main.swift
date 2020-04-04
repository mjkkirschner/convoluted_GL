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
    var callback: @convention(c) () -> Void
    
    init(width:Int,height:Int) {
        win = NSWindow(contentRect: NSMakeRect(100, 100, CGFloat(width), CGFloat(height)),
                    styleMask: [.titled, .miniaturizable,.closable,.resizable],
                     backing: NSWindow.BackingStoreType.buffered, defer: true);
        imageWidth = width;
        imageHeight = height;
        
        print(imageWidth);
        print(imageHeight);
     
        imageData = [UInt8]();
        imageData.reserveCapacity(imageWidth*imageHeight*4);
        pointer = UnsafeMutablePointer(&imageData);
        self.callback = { };
    }

     func applicationDidFinishLaunching(_ aNotification: Notification)
        {
             print("inside finish launch");
             print("makeKey window");

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
                let start = DispatchTime.now() // <<<<<<<<<< Start time
                print("inside timer, updating texture on quad");
                tex2dRendererInstance.UpdateTextureWithColorDataPointer(tex: tex2dRendererInstance.texture,pointer: self.pointer);
                
                if(self.callback != nil){
                    print("executing render callback")
                    self.callback();
                }
                let end = DispatchTime.now() // <<<<<<<<<< Start time
                print("took",Double(end.uptimeNanoseconds-start.uptimeNanoseconds)/1_000_000_000,"to render frame");

            }
            
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
public func start_render_view(width:Int,height:Int,renderfunc: @escaping @convention(c) () -> Void ){

    
    let app = NSApplication.shared;
   
    controller =  TestApplicationController(width: width,height: height);
    renderfunc();
    controller?.callback = renderfunc;

    app.delegate = controller;
     print("about to try running the application")
    app.run();
    
    print("GoodBye, World - from swift!");
}

 //this should be called externally point to some color data in RGBA8 format.
@_cdecl("update_tex")
public func update_tex(data:UnsafeMutablePointer<uint8>){
    controller?.updateTextureData(data: data);
}


