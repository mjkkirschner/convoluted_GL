//
//  main.cpp
//  opengl_window_c
//
//  Created by Michael Kirschner on 3/29/20.
//  Copyright © 2020 Michael Kirschner. All rights reserved.
//

#include <iostream>
#include <OpenGL/OpenGL.h> 
#include <OpenGL/gl3.h>
#include <OpenGl/glu.h>
#include <GLUT/glut.h>
#include <OpenGL/CGLTypes.h>
#include <OpenGL/CGLCurrent.h>
#include <thread>
#include <unistd.h>

#define GL_SILENCE_DEPRECATION

// only "extern" when targeting C.
extern "C" int start_render_view(int width,int height);

//TODO this apparently takes a unit8?...odd..guess each color channel.. so we need a bigger array.
extern "C" void update_tex(uint8_t* data);


GLuint program;
unsigned int framebuffer;
uint8_t imageBufffer [800*800*4];



bool init_resources() {
    
    char data[100000];
    int size;
    
    GLint compile_ok = GL_FALSE, link_ok = GL_FALSE;
    
    GLuint vs = glCreateShader(GL_VERTEX_SHADER);
    const char *vs_source =
        "#version 400\n"
        "layout (location = 0) in vec3 aPos;"
        "void main() {                        "
        "  gl_Position = vec4(aPos.x,aPos.y,aPos.z, 1.0); "
        "}";
    
    glShaderSource(vs, 1, &vs_source, NULL);
    glCompileShader(vs);
    glGetShaderiv(vs, GL_COMPILE_STATUS, &compile_ok);
    if (!compile_ok) {
        std::cerr << "Error in vertex shader" << std::endl;
        glGetShaderInfoLog(vs,100000,&size,data);
        std::cout << data  << std::endl;
        return false;
    }
    
    GLuint fs = glCreateShader(GL_FRAGMENT_SHADER);
    const char *fs_source =
        //"#version 100\n"  // OpenGL ES 2.0
        "#version 400\n"  // OpenGL 2.1
        "out vec4 FragColor;"
        "void main(void) {"
       "FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);"
        "}";
    glShaderSource(fs, 1, &fs_source, NULL);
    glCompileShader(fs);
    glGetShaderiv(fs, GL_COMPILE_STATUS, &compile_ok);
    if (!compile_ok) {
        std::cerr << "Error in fragment shader" << std::endl;
        glGetShaderInfoLog(fs,100000,&size,data);
             std::cout << data  << std::endl;
        return false;
    }
    
    program = glCreateProgram();
    glAttachShader(program, vs);
    glAttachShader(program, fs);
    glLinkProgram(program);
    glGetProgramiv(program, GL_LINK_STATUS, &link_ok);
    if (!link_ok) {
        std::cerr << "Error in glLinkProgram" << std::endl;
        return false;
    }

    
    //setup famebuffer
      glGenFramebuffers(1, &framebuffer);
      glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
        
    // generate texture
    unsigned int texColorBuffer;
    glGenTextures(1, &texColorBuffer);
    glBindTexture(GL_TEXTURE_2D, texColorBuffer);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, 800, 800, 0, GL_RGB, GL_UNSIGNED_BYTE, 0);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glBindTexture(GL_TEXTURE_2D, 0);

    // attach it to currently bound framebuffer object
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texColorBuffer, 0);
    
    unsigned int rbo;
    glGenRenderbuffers(1, &rbo);
    glBindRenderbuffer(GL_RENDERBUFFER, rbo);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT, 800, 800);
    glBindRenderbuffer(GL_RENDERBUFFER, 0);

    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, rbo); // now actually attach it
    
    if(glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE){
        std::cout << "ERROR::FRAMEBUFFER:: Framebuffer is not complete!" << std::endl;
        return false;
    }
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    
    
    return true;
}

void render(uint8_t* outputbuffer,unsigned int framebuffer) {
    int error;

    // bind to framebuffer and draw scene as we normally would to color texture
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
  glViewport(0, 0, 800, 800);
    error = glGetError();
    glClearColor(0, 0, 1.0, 1.0);
      glClear(GL_COLOR_BUFFER_BIT);
error = glGetError();

  glUseProgram(program);
 error = glGetError();
    
   float vertices[] = {
        -0.5f, -0.5f, 0.0f,
         0.5f, -0.5f, 0.1f,
         0.0f,  0.5f, 0.1f
    };
    
    unsigned int VBO, VAO;
    glGenVertexArrays(1, &VAO);
     error = glGetError();
       glGenBuffers(1, &VBO);
     error = glGetError();
       // bind the Vertex Array Object first, then bind and set vertex buffer(s), and then configure vertex attributes(s).
    glBindVertexArray(VAO);
     error = glGetError();
       glBindBuffer(GL_ARRAY_BUFFER, VBO);
     error = glGetError();
       glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
     error = glGetError();
       glEnableVertexAttribArray(0);
     error = glGetError();
       glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(float), (void*)0);
         error = glGetError();
    /* Push each element in buffer_vertices to the vertex shader */
    glDrawArrays(GL_TRIANGLES,0, 3);
     error = glGetError();
    glDisableVertexAttribArray(0);
     error = glGetError();
  
    error = glGetError();
    glBindFramebuffer(GL_READ_FRAMEBUFFER,framebuffer);
    
    error = glGetError();
    glReadPixels(0, 0, 800, 800, GL_RGBA, GL_UNSIGNED_BYTE, outputbuffer);
    error = glGetError();
    glFinish();
    error = glGetError();
}

void free_resources() {
    glDeleteProgram(program);
}

void task(uint8_t* buffer){
    //wait a while... until the window is open
    //so that calling updateTex actually effects the renderer.
    usleep(10000000);
    
    //windowless opengl context:
      //http://renderingpipeline.com/2012/05/windowless-opengl-on-macos-x/
    
    CGLContextObj context;
     
     const CGLPixelFormatAttribute attributes[] = {
      kCGLPFAAccelerated,   // no software rendering
      kCGLPFAOpenGLProfile, // core profile with the version stated below
      (CGLPixelFormatAttribute) kCGLOGLPVersion_GL4_Core,
      (CGLPixelFormatAttribute) 0
    };
    
      CGLPixelFormatObj pix;
     CGLError errorCode;
     GLint num; // stores the number of possible pixel formats
     errorCode = CGLChoosePixelFormat( attributes, &pix, &num );
     // add error checking here
     errorCode = CGLCreateContext( pix, NULL, &context ); // second parameter can be another context for object sharing
     // add error checking here
      CGLDestroyPixelFormat( pix );
    
     errorCode = CGLSetCurrentContext( context );
     // add error checking here
     std::cout << std::endl <<  glGetString(GL_VERSION) << std::endl;
     std::cout << std::endl << "called from cpp" << std::endl;
    
    init_resources();
    std::cout << std::endl << "render" << std::endl;
    render(imageBufffer, framebuffer);
    std::cout << std::endl << "updateTex" << std::endl;
    update_tex(buffer);
}

int main(int argc, char **argv) {
   
  
    
    //do all rendering on a different thread.
    std::thread t1(task, imageBufffer);
    //start main window on main thread. - this is blocking.
    int window = start_render_view(800,800);
        
    return 0;
}


