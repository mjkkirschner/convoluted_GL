//
//  main.cpp
//  opengl_window_c
//
//  Created by Michael Kirschner on 3/29/20.
//  Copyright © 2020 Michael Kirschner. All rights reserved.
//

#include <iostream>
#include <OpenGL/gl.h>
#include <OpenGl/glu.h>
#include <GLUT/glut.h>
// only "extern" when targeting C.
extern "C" int start_render_view(int width,int height);

GLuint program;
GLint attribute_coord2d;

bool init_resources() {
    GLint compile_ok = GL_FALSE, link_ok = GL_FALSE;

    GLuint vs = glCreateShader(GL_VERTEX_SHADER);
    const char *vs_source =
        //"#version 100\n"  // OpenGL ES 2.0
        "#version 120\n"  // OpenGL 2.1
        "attribute vec2 coord2d;                  "
        "void main(void) {                        "
        "  gl_Position = vec4(coord2d, 0.0, 1.0); "
        "}";
    
    glShaderSource(vs, 1, &vs_source, NULL);
    glCompileShader(vs);
    glGetShaderiv(vs, GL_COMPILE_STATUS, &compile_ok);
    if (!compile_ok) {
        std::cerr << "Error in vertex shader" << std::endl;
        return false;
    }
    
    GLuint fs = glCreateShader(GL_FRAGMENT_SHADER);
    const char *fs_source =
        //"#version 100\n"  // OpenGL ES 2.0
        "#version 120\n"  // OpenGL 2.1
        "void main(void) {        "
        "  gl_FragColor[0] = 0.0; "
        "  gl_FragColor[1] = 0.0; "
        "  gl_FragColor[2] = 1.0; "
        "}";
    glShaderSource(fs, 1, &fs_source, NULL);
    glCompileShader(fs);
    glGetShaderiv(fs, GL_COMPILE_STATUS, &compile_ok);
    if (!compile_ok) {
        std::cerr << "Error in fragment shader" << std::endl;
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
    
    const char* attribute_name = "coord2d";
    attribute_coord2d = glGetAttribLocation(program, attribute_name);
    if (attribute_coord2d == -1) {
        std::cerr << "Could not bind attribute " << attribute_name << std::endl;
        return false;
    }

    return true;
}

void render(int* window) {
    /* Clear the background as white */
    glClearColor(1.0, 1.0, 1.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);

    glUseProgram(program);
    glEnableVertexAttribArray(attribute_coord2d);
    GLfloat triangle_vertices[] = {
        0.0,  0.8,
       -0.8, -0.8,
        0.8, -0.8,
    };
    /* Describe our vertices array to OpenGL (it can't guess its format automatically) */
    glVertexAttribPointer(
        attribute_coord2d, // attribute
        2,                 // number of elements per vertex, here (x,y)
        GL_FLOAT,          // the type of each element
        GL_FALSE,          // take our values as-is
        0,                 // no extra data between each position
        triangle_vertices  // pointer to the C array
                          );
    
    /* Push each element in buffer_vertices to the vertex shader */
    glDrawArrays(GL_TRIANGLES, 0, 3);
    
    glDisableVertexAttribArray(attribute_coord2d);

    /* Display the result */
    
      // Display it
    ()
    glXSwapBuffers( window.display, Win.win );

}

void free_resources() {
    glDeleteProgram(program);
}


int main(int argc, const char * argv[]) {
    int window = start_render_view(1500,1500);
    std::cout << std::endl << "called from cpp" << std::endl;
    
    GLfloat triangle_vertices[] = {
        0.0,  0.8,
       -0.8, -0.8,
        0.8, -0.8,
    };
    
    render(window);
    
    
    return 0;
}
