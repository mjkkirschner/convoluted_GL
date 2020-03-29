//
//  main.swift
//  openGL_window
//
//  Created by Michael Kirschner on 3/29/20.
//  Copyright © 2020 Michael Kirschner. All rights reserved.
//

import Foundation
import AppKit



@_cdecl("start_render_view")
public func start_render_view(width:Int,height:Int){
    var controller:ApplicationController? = nil;

    print("Hello, World - from swift!")
    let app = NSApplication.shared;
    controller =  ApplicationController(width: width,height: height);
    app.delegate = controller;
     print("about to try running")
    app.run();
    
    print("GoodBye, World - from swift!");
}

final class ApplicationController: NSObject, NSApplicationDelegate
{
    var win:NSWindow;
    var imageWidth:Int;
    var imageHeight:Int;
    
    init(width:Int,height:Int) {
        win = NSWindow(contentRect: NSMakeRect(100, 100, CGFloat(width), CGFloat(height)),
                    styleMask: [.titled, .miniaturizable,.closable,.resizable],
                     backing: NSWindow.BackingStoreType.buffered, defer: true);
        imageWidth = width;
        imageHeight = height;
        NSOpenGLPixelFormatAttribute
        win.nsgl
        print(imageWidth);
        print(imageHeight);

    }
    
    
     func applicationDidFinishLaunching(_ aNotification: Notification)
        {
             print("inside finish launch");
             win.makeKeyAndOrderFront(self);
             print("makeKey window");
            }
            

        func applicationWillTerminate(_ aNotification: Notification) {
                // Insert code here to tear down your application
        }
}



