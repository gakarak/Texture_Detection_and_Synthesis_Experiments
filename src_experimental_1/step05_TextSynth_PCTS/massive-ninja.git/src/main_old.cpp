#include <GL/glew.h>
#include <GL/glfw.h>
#include <stdlib.h>
#include <fstream>
#include <iostream>
using std::cout; using std::endl;

// global variables to store the scene geometry
GLuint vertexArrayID;
GLuint bufferIDs[3];

// initialize the scene geometry
void initGeometry() {
	static const GLfloat rawVertexData[12] = { -1.0f,-1.0f,0.0f,  -1.0f,1.0f,0.0f,  1.0f,-1.0f,0.0f, 1.0f,1.0f,0.0f };
	static const GLfloat rawColorData[12]  = {  1.0f,0.0f,0.0f,  0.0f,1.0f,0.0f,  0.0f,0.0f,1.0f, 1.0f, 1.0f, 0.0f };
	static const GLfloat rawUVData[8] = {0,0, 0,1, 1,0, 1,1};
    // create a new renderable object and set it to be active
	glGenVertexArrays(1,&vertexArrayID);
	glBindVertexArray(vertexArrayID);
	// create buffers for associated data
	glGenBuffers(3,bufferIDs);
	// set a buffer to be active and shove vertex data into it
	glBindBuffer(GL_ARRAY_BUFFER, bufferIDs[0]);
	glBufferData(GL_ARRAY_BUFFER, 12*sizeof(GLfloat), rawVertexData, GL_STATIC_DRAW);
	// bind that data to shader variable 0
	glVertexAttribPointer((GLuint)0, 3, GL_FLOAT, GL_FALSE, 0, 0);
	glEnableVertexAttribArray(0);
	// set a buffer to be active and shove color data into it
	glBindBuffer(GL_ARRAY_BUFFER, bufferIDs[1]);
	glBufferData(GL_ARRAY_BUFFER, 12*sizeof(GLfloat), rawColorData, GL_STATIC_DRAW);
	// bind that data to shader variable 1
	glVertexAttribPointer((GLuint)1, 3, GL_FLOAT, GL_FALSE, 0, 0);
	glEnableVertexAttribArray(1);

    glBindBuffer(GL_ARRAY_BUFFER, bufferIDs[2]);
    glBufferData(GL_ARRAY_BUFFER, 8*sizeof(GLfloat), rawUVData, GL_STATIC_DRAW);
    glVertexAttribPointer((GLuint)2, 2, GL_FLOAT, GL_FALSE, 0, 0);
	glEnableVertexAttribArray(2);
}

// loadFile - loads text file into char* fname
// allocates memory - so need to delete after use
// size of file returned in fSize
char* loadFile(const char *fname, GLint &fSize) {
	std::ifstream::pos_type size;
	char * memblock;

	// file read based on example inhttp://bitsquid.se/presentations/flexible-rendering-multiple-platforms.pdf cplusplus.com tutorial
	std::ifstream file (fname, std::ios::in|std::ios::binary|std::ios::ate);
	if (file.is_open()) {
		size = file.tellg();
		fSize = (GLuint) size;
		memblock = new char [size];
		file.seekg (0, std::ios::beg);
		file.read (memblock, size);
		file.close();
	} else {
		std::cout << "Unable to open " << fname << std::endl;
		exit(1);
	}
	cout << fname << " loaded" << endl;
	return memblock;
}

GLuint compileShader(const char *fname, GLuint type) {
	GLuint shader;
	GLint length;
	// create a shader ID
	shader = glCreateShader(type);
	// load the file into memory and try to compile it
	char *source = loadFile(fname,length);
	glShaderSource(
shader, 1, (const GLchar**)&source,&length);
	GLint compiled;
	glCompileShader(shader);
	// print out errors if they're there
	glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);
	if (!compiled) {
		std::cout << fname << " failed to compile" << std::endl;
		// find the error length
		glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &length);
		if (length>0) {
			// print the errors
			char *error = new GLchar[length];
			GLint written;
			glGetShaderInfoLog(shader,length, &written, error);
			std::cout << "Error log:\n" << error << std::endl;
			delete[] error;
		}
	}
	delete[] source;
	return shader;
}

GLuint initShaders(const char * vert, const char * frag) {
	GLuint p, f, v;
	// get the shader code
	v = compileShader(vert,GL_VERTEX_SHADER);
	f = compileShader(frag,GL_FRAGMENT_SHADER);
	// the GLSL program links shaders together to form the render pipeline
	p = glCreateProgram();
	// assign numerical IDs to the variables that we pass to the shaders 
	glBindAttribLocation(p,0, "in_Position");
	glBindAttribLocation(p,1, "in_Color");
	glBindAttribLocation(p,2, "in_UV");	
	//glBindAttribLocation(p,3, "tex");
	// bind our shaders to this program
	glAttachShader(p,v);
	glAttachShader(p,f);
	// link things together and activate the shader
	glLinkProgram(p);
	return p;
}

// Callback for when the window is resized
void GLFWCALL windowResize( int width, int height ) {
	glViewport(0,0,(GLsizei)width,(GLsizei)height);
}

GLuint createBlankTex(GLuint size) {
	static GLuint texture;
    glGenTextures(1,&texture);
    glBindTexture( GL_TEXTURE_2D, texture );
    glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT );
    glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT ); 
    void* data = calloc(size*size,sizeof(GLuint));
    glTexImage2D(GL_TEXTURE_2D,0,GL_RGB16,size,size,0,GL_RGB,GL_UNSIGNED_SHORT,0);
    free(data);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    return texture;
}

void checkGlError(int l) {
	GLenum error = glGetError();
	if (error!=0) cout << "Location: " << l << endl;
	switch (error) {
		case GL_NO_ERROR: break;
		case GL_INVALID_VALUE: cout << "GL_INVALID_VALUE" << endl; break;
		case GL_INVALID_OPERATION: cout << "GL_INVALID_OPERATION" << endl; break;
		case GL_INVALID_ENUM: cout << "GL_INVALID_ENUM" << endl; break;
		case GL_INVALID_FRAMEBUFFER_OPERATION: cout << "GL_INVALID_FRAMEBUFFER_OPERATION" << endl; break;
		case GL_OUT_OF_MEMORY: cout << "GL_OUT_OF_MEMORY" << endl; break;
		case GL_STACK_UNDERFLOW: cout << "GL_STACK_UNDERFLOW" << endl; break;
		case GL_STACK_OVERFLOW: cout << "GL_STACK_OVERFLOW" << endl; break;
		default: cout << "Unknown OpenGL Error: " << error << endl;
	};
}

GLuint createFBO(GLuint texture) {
    GLuint FBO;
    glGenFramebuffers(1,&FBO);
    glBindFramebuffer(GL_FRAMEBUFFER,FBO);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texture, 0);
    GLenum DrawBuffers[2] = {GL_COLOR_ATTACHMENT0};
    glDrawBuffers(1,DrawBuffers);
    return FBO;
}

GLuint runAlgorithm(GLuint pyramid[], GLuint exemplar,GLuint q) {
	GLuint p = initShaders("minimal.vert", "minimal.frag");
	GLuint r = initShaders("minimal.vert", "correction.frag");
	GLint r_exemplar = glGetUniformLocation(r,"example_texture");
	GLint r_tex = glGetUniformLocation(r, "res");
	GLint r_coords_x = glGetUniformLocation(r,"coords_x");
	GLint r_coords_y = glGetUniformLocation(r,"coords_y");
	cout << r_tex << ": " << r_exemplar << endl;
	cout << r_coords_x << ": " << r_coords_y << endl;

	checkGlError(8);
	GLint tex = glGetUniformLocation(p, "tex");
	glUseProgram(p);
	cout << tex << endl;
	GLint m = glGetUniformLocation(p,"m");
	checkGlError(9);
	glUniform1ui(m,512);
	checkGlError(0);
	
	//GLuint FBO[10];
	//glGenFramebuffers(10, FBO);
	int size[10] = {1,2,4,8,16,32,64,128,256,512};
	//cout << "GL_FRAMEBUFFER_COMPLETE: " << GL_FRAMEBUFFER_COMPLETE << endl;
	for (GLuint i=1; i<10; ++i) {
        GLuint ttex = createBlankTex(size[i]);	
        GLuint ttex2 = createBlankTex(size[i]);
		// bind textures
		glActiveTexture(GL_TEXTURE0);
		glBindTexture(GL_TEXTURE_2D, pyramid[i-1]);
		glActiveTexture(GL_TEXTURE1);
		glBindTexture(GL_TEXTURE_2D, exemplar);
	
		GLuint FBO = createFBO(ttex);
        glUseProgram(p);
		glBindFragDataLocation(p,0,"colorOut");
		GLint m = glGetUniformLocation(p,"m");
		glUniform1ui(m,96);
		glPushAttrib(GL_VIEWPORT_BIT | GL_ENABLE_BIT);
		glViewport(0, 0, size[i], size[i]);
		checkGlError(2);
		
		tex = glGetUniformLocation(p, "tex");
		glUniform1i(tex, 0);
		glClear( GL_COLOR_BUFFER_BIT );
		glBindVertexArray(vertexArrayID);
		glDrawArrays(GL_TRIANGLE_STRIP,0,4);
		//glfwSwapBuffegetkeyrs();
		glBindFramebuffer(GL_FRAMEBUFFER,0);
		glDeleteFramebuffers(1,&FBO);
        glPopAttrib();
	
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D,ttex);
        FBO = createFBO(pyramid[i]);
        glUseProgram(r);
        glBindFragDataLocation(r,0,"out_color");
		glPushAttrib(GL_VIEWPORT_BIT | GL_ENABLE_BIT);
		glViewport(0, 0, size[i], size[i]);
        glUniform1i(r_exemplar,1);
        glUniform1i(r_tex,0);
        glUniform1i(r_coords_x,1);
        glUniform1i(r_coords_y,1);
        
		glClear( GL_COLOR_BUFFER_BIT );
		glBindVertexArray(vertexArrayID);
        glDrawArrays(GL_TRIANGLE_STRIP,0,4);
        glBindFramebuffer(GL_FRAMEBUFFER,0);
        glDeleteFramebuffers(1,&FBO);
		checkGlError(2);
        glPopAttrib();
		/*
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D,ttex2);
        FBO = createFBO(pyramid[i]);
        glUseProgram(r);
        glBindFragDataLocation(r,0,"out_color");
		glPushAttrib(GL_VIEWPORT_BIT | GL_ENABLE_BIT);
		glViewport(0, 0, size[i], size[i]);
        glUniform1i(r_exemplar,1);
        glUniform1i(r_tex,0);
        
        glClear(GL_COLOR_BUFFER_BIT);
        glBindVertexArray(vertexArrayID);
        glDrawArrays(GL_TRIANGLE_STRIP,0,4);
        glBindFramebuffer(GL_FRAMEBUFFER,0);
        glDeleteFramebuffers(1,&FBO);
		checkGlError(2);
        glPopAttrib();*/
    }
	glBindFramebuffer(GL_FRAMEBUFFER,0);
	glBindRenderbuffer(GL_RENDERBUFFER,0);
	glUseProgram(q);
    return p;
}

int main( void ) {
	// Initialize GLFW
	if( !glfwInit() ) {
		exit( EXIT_FAILURE );
	}
	// Open an OpenGL window
	if( !glfwOpenWindow( 512,512, 0,0,0,0,0,0, GLFW_WINDOW ) ) {
		glfwTerminate();
		exit( EXIT_FAILURE );
	}
	glfwSetWindowTitle("Triangle");
	glfwSetWindowSizeCallback( windowResize );
	glfwSwapInterval( 1 ); 
	windowResize(512,512);
	glewInit();
	glClearColor(1.0f, 0.0f, 0.0f, 0.0f);
	glClearDepth(1.0f);
	glEnable(GL_DEPTH_TEST);
	glDepthFunc(GL_LEQUAL);
	initGeometry();
	glEnable( GL_TEXTURE_2D );
	GLuint q = initShaders("minimal.vert", "tex.frag");
    // Main loop
	glActiveTexture(GL_TEXTURE0);
    GLuint pyramid[10];
    for (int i = 0, j=1; i<10; ++i, j*=2) {
        pyramid[i] = createBlankTex(j);
		cout << pyramid[i] << endl;
    }
	GLuint example;
    glGenTextures(1,&example);
	checkGlError(98);
	cout << example << endl;
	GLFWimage imbuf;
	glfwReadImage("rice.tga",&imbuf,0);
	cout << imbuf.Width << endl << imbuf.Height << endl;
	glActiveTexture(GL_TEXTURE1);
	glBindTexture(GL_TEXTURE_2D, example);
    glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT );
    glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT );
	glTexImage2D(GL_TEXTURE_2D,0,GL_RGB,imbuf.Width,imbuf.Height,0,imbuf.Format,GL_UNSIGNED_BYTE,(void*)imbuf.Data);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	checkGlError(99);
	//cout << example << endl;
    runAlgorithm(pyramid,example,q);
    int running = GL_TRUE;
	int hasrun= GL_TRUE;
    int firstrun = GL_TRUE;
	GLint tex = glGetUniformLocation(q, "tex");
	GLint exemplar = glGetUniformLocation(q,"exemplar");
	GLint mode = glGetUniformLocation(q,"mode");
	
    glUniform1i(tex, 0);
	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, pyramid[9]);
    glUniform1i(exemplar,1);

	glActiveTexture(GL_TEXTURE1);
	glBindTexture(GL_TEXTURE_2D, example);
    glUniform1i(mode, 0);
    while( running ) {
	    if (glfwGetKey(GLFW_KEY_SPACE) || firstrun == GL_TRUE) {
            firstrun = GL_FALSE;
            if (hasrun == GL_FALSE) {
                hasrun = GL_TRUE;
                runAlgorithm(pyramid,example, q);
				glViewport(0,0,512,512);
            }
        } else {
            hasrun = GL_FALSE;
        }
		for (unsigned int i = 0; i<10; ++i) {
			if (glfwGetKey('0'+i)) {
				glUniform1i(tex,0);
				glActiveTexture(GL_TEXTURE0);
				glBindTexture(GL_TEXTURE_2D, pyramid[i]);
				glUniform1i(exemplar,1);
				glActiveTexture(GL_TEXTURE1);
				glBindTexture(GL_TEXTURE_2D, example);
			}
		}
		if (glfwGetKey(GLFW_KEY_F1)) {
			glUniform1i(mode, 0);
		}
		if (glfwGetKey(GLFW_KEY_F2)) {
			glUniform1i(mode, 1);
		}
		if (glfwGetKey(GLFW_KEY_F3)) {
			glUniform1i(mode, 2);
		}
        // OpenGL rendering goes here...
		glClear( GL_COLOR_BUFFER_BIT );
		// draw the triangle
		glBindVertexArray(vertexArrayID);
		glDrawArrays(GL_TRIANGLE_STRIP,0,4);
		// Swap front and back rendering buffers
		glfwSwapBuffers();
		// Check if ESC key was pressed or window was closed
		running = !glfwGetKey( GLFW_KEY_ESC ) && glfwGetWindowParam( GLFW_OPENED );
	}
	// Close window and terminate GLFW
	glfwTerminate();
	// Exit program
	exit( EXIT_SUCCESS );
}
