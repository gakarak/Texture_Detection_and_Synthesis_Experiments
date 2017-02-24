#include <GL/glew.h>
#include <GL/glfw.h>
//#include <GLFW/glfw3.h>
#include <stdlib.h>
#include <fstream>
#include <iostream>

#include <opencv2/highgui.hpp>
#include <opencv2/imgproc.hpp>

#include <unistd.h>

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
	glShaderSource( shader, 1, (const GLchar**)&source,&length);
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
    GLushort* data = (GLushort*)calloc(size*size,4 * sizeof(GLushort));
    if (size==1) {
        data[0] = data[1] = 8;
    }
    glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA16,size,size,0,GL_RGB,GL_UNSIGNED_SHORT,data);
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
    static GLenum DrawBuffers[2] = {GL_COLOR_ATTACHMENT0};
    glDrawBuffers(1,DrawBuffers);
    return FBO;
}

GLuint createFBO(GLuint texture, GLuint texture2) {
    GLuint FBO;
    glGenFramebuffers(1,&FBO);
    glBindFramebuffer(GL_FRAMEBUFFER,FBO);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texture, 0);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT1, GL_TEXTURE_2D, texture2, 0);
    GLenum *DrawBuffers = new GLenum[2];
    DrawBuffers[0] = GL_COLOR_ATTACHMENT0;
    DrawBuffers[1] = GL_COLOR_ATTACHMENT1;
    glDrawBuffers(2,DrawBuffers);
    cout << glCheckFramebufferStatus(GL_FRAMEBUFFER) << endl;
    return FBO;
}

GLuint runAlgorithm(GLuint pyramid[], GLuint pyramid_x[], GLuint pyramid_y[], GLuint pyramid_z[], GLuint exemplar, GLint matches_x, GLint matches_y) {
    // init shaders (minimal, correction, kcohere, all with minimal.vert as vert shader)
	GLuint p = initShaders("minimal.vert", "minimal.frag");
	GLuint r = initShaders("minimal.vert", "correction.frag");
	GLuint k = initShaders("minimal.vert", "kcohere.frag");

    // setup the inputs for the correction.frag shader
    GLint r_tex      = glGetUniformLocation(r, "res");
	GLint r_exemplar = glGetUniformLocation(r,"example_texture");
    GLint r_coords_x = glGetUniformLocation(r,"coords_x");
    GLint r_coords_y = glGetUniformLocation(r,"coords_y");
	cout << r_tex << r_exemplar << r_coords_x << r_coords_y << endl;

    // setup the inputs for the kcohere.frag shader
    GLint k_tex = glGetUniformLocation(k,"res");
    GLint k_exemplar = glGetUniformLocation(k,"example_texture");
	GLint k_matches_x = glGetUniformLocation(k,"matches_x");
    GLint k_matches_y = glGetUniformLocation(k,"matches_y");
    cout << "matches: " << k_matches_x << "\t" << k_matches_y << endl;	
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
	cout << "GL_FRAMEBUFFER_COMPLETE: " << GL_FRAMEBUFFER_COMPLETE << endl;
	for (GLuint i=1; i<10; ++i) {
        // initialize blank textures
        GLuint ttex = createBlankTex(size[i]);	
        GLuint ttex2 = createBlankTex(size[i]);
        GLuint ttex3 = createBlankTex(size[i]);

		// shader pass 1 bind textures
		glActiveTexture(GL_TEXTURE0);
		glBindTexture(GL_TEXTURE_2D, pyramid[i-1]);
		glActiveTexture(GL_TEXTURE1);
		glBindTexture(GL_TEXTURE_2D, exemplar);
	
        GLuint FBO = createFBO((i<3?pyramid[i]:pyramid_z[i]));
        glUseProgram(p);
		glBindFragDataLocation(p,0,"colorOut");
		GLint m = glGetUniformLocation(p,"m");
		glUniform1ui(m,64);
		//glUniform1ui(m,128);
		glPushAttrib(GL_VIEWPORT_BIT | GL_ENABLE_BIT);
		glViewport(0, 0, size[i], size[i]);
		checkGlError(2);
		
		tex = glGetUniformLocation(p, "tex");
		glUniform1i(tex, 0);
		glClear( GL_COLOR_BUFFER_BIT );
		glBindVertexArray(vertexArrayID);
		glDrawArrays(GL_TRIANGLE_STRIP,0,4);
		glBindFramebuffer(GL_FRAMEBUFFER,0);
		glDeleteFramebuffers(1,&FBO);
        glPopAttrib();
       if (i<3) {
            continue;
        }
        // shader pass 2	
        for (int j=0; j<5; ++j) {
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D,(j==0?pyramid_z[i]:pyramid[i]));
        glActiveTexture(GL_TEXTURE4);
        glBindTexture(GL_TEXTURE_2D,matches_x);
        glActiveTexture(GL_TEXTURE5);
        glBindTexture(GL_TEXTURE_2D,matches_y);
        //FBO = createFBO(ttex2,ttex3);
        FBO = createFBO(pyramid_x[i], pyramid_y[i]);
        glUseProgram(k);
        glBindFragDataLocation(k,0,"kcoh_set_x");
        cout << "X: " << glGetFragDataLocation(k,"kcoh_set_x") << endl;
        glBindFragDataLocation(k,1,"kcoh_set_y");
        cout << "Y: " << glGetFragDataLocation(k,"kcoh_set_y") << endl;
		glPushAttrib(GL_VIEWPORT_BIT | GL_ENABLE_BIT);
		glViewport(0, 0, size[i], size[i]);
        glUniform1i(k_exemplar,1);
        glUniform1i(k_tex,0);
        glUniform1i(k_matches_x,4);
        glUniform1i(k_matches_y,5);    
    
		glClear( GL_COLOR_BUFFER_BIT );
		glBindVertexArray(vertexArrayID);
        glDrawArrays(GL_TRIANGLE_STRIP,0,4);
        glBindFramebuffer(GL_FRAMEBUFFER,0);
        glDeleteFramebuffers(1,&FBO);
		checkGlError(2);
        glPopAttrib();
        
        // shader pass 3
        glActiveTexture(GL_TEXTURE2);
        glBindTexture(GL_TEXTURE_2D,pyramid_x[i]);
        glActiveTexture(GL_TEXTURE3);
        glBindTexture(GL_TEXTURE_2D,pyramid_y[i]);
        FBO = createFBO(pyramid[i]);
        glUseProgram(r);
        glBindFragDataLocation(r,0,"colorOut");
		glPushAttrib(GL_VIEWPORT_BIT | GL_ENABLE_BIT);
		glViewport(0, 0, size[i], size[i]);
        glUniform1i(r_exemplar,1);
        glUniform1i(r_tex,0);
        glUniform1i(r_coords_x,2);
        glUniform1i(r_coords_y,3);
        glClear(GL_COLOR_BUFFER_BIT);
        glBindVertexArray(vertexArrayID);
        glDrawArrays(GL_TRIANGLE_STRIP,0,4);
        glBindFramebuffer(GL_FRAMEBUFFER,0);
        glDeleteFramebuffers(1,&FBO);
		checkGlError(2);
        glPopAttrib();
        }
    }
	glBindFramebuffer(GL_FRAMEBUFFER,0);
	glBindRenderbuffer(GL_RENDERBUFFER,0);
    return p;
}

void prepass(GLuint exemplar, GLuint size, GLuint &matches_x, GLuint &matches_y) {
    // initialize the shaders
    //GLuint prepass = initShaders("minimal.vert", "test.frag");
    GLuint prepass = initShaders("minimal.vert", "prepass.frag");
    GLint exemplar_loc = glGetUniformLocation(prepass, "exemplar");
    glUseProgram(prepass);
    
    // initialize the framebuffer
	matches_x = createBlankTex(size);
    matches_y = createBlankTex(size);
    GLuint FBO = createFBO(matches_x, matches_y);

    // configure shader inputs
    glUniform1i(exemplar_loc,0);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, exemplar);

    // configure shader outputs
    glBindFragDataLocation(prepass,0,"matches_x");
    glBindFragDataLocation(prepass,1,"matches_y");

    // initialize the rendering state
    glPushAttrib(GL_VIEWPORT_BIT | GL_ENABLE_BIT);
    glViewport(0, 0, size, size);    

    // execute the prepass
    glBindVertexArray(vertexArrayID);
    glDrawArrays(GL_TRIANGLE_STRIP,0,4);
    
    // release resources
    glBindFramebuffer(GL_FRAMEBUFFER,0);
    glDeleteFramebuffers(1,&FBO);
    glDeleteProgram(prepass);
    glPopAttrib();
}

int main( void ) {
    chdir("../src");

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
	GLuint q = initShaders("minimal.vert", "tex.frag");
    // Main loop
	glActiveTexture(GL_TEXTURE0);
    GLuint pyramid_x[10];
    GLuint pyramid_y[10];
    GLuint pyramid_u[10];
    GLuint pyramid[10];
    for (int i = 0, j=1; i<10; ++i, j*=2) {
        pyramid[i] = createBlankTex(j);
        pyramid_x[i] = createBlankTex(j);
        pyramid_y[i] = createBlankTex(j);
		pyramid_u[i] = createBlankTex(j);
        cout << pyramid[i] << endl;
    }
	GLuint example;
    glGenTextures(1,&example);
	cout << example << endl;
	GLFWimage imbuf;
    glfwReadImage("regular.tga",&imbuf,0);
//	glfwReadImage("rice.tga",&imbuf,0);
//    glfwReadImage("rice_64x64.tga",&imbuf,0);
//    glfwReadImage("18_64x64.tga",&imbuf,0);
    cout << imbuf.Width << endl << imbuf.Height << endl;
	glActiveTexture(GL_TEXTURE1);
	glBindTexture(GL_TEXTURE_2D, example);
    glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT );
    glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT );
	glTexImage2D(GL_TEXTURE_2D,0,GL_RGB,imbuf.Width,imbuf.Height,0,imbuf.Format,GL_UNSIGNED_BYTE,(void*)imbuf.Data);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    cout << imbuf.Width << imbuf.Height << endl;
	checkGlError(99);
	//cout << example << endl;
    
    GLuint matches_x, matches_y;
    prepass(example, 64, matches_x, matches_y);
//    prepass(example, 128, matches_x, matches_y);

    runAlgorithm(pyramid, pyramid_x, pyramid_y, pyramid_u, example, matches_x, matches_y);
    glUseProgram(q);
    int running = GL_TRUE;
//    int running = GL_FALSE;
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
    
    glActiveTexture(GL_TEXTURE4);
    glBindTexture(GL_TEXTURE_2D, matches_x);
    glActiveTexture(GL_TEXTURE5);
    glBindTexture(GL_TEXTURE_2D, matches_y);
    
    GLint u_matches_x = glGetUniformLocation(q,"matches_x");
    GLint u_matches_y = glGetUniformLocation(q,"matches_y");

    glUniform1i(u_matches_x, 4);
    glUniform1i(u_matches_y, 5);

    glUniform1i(mode, 0);
    int set = 0;
    while( running ) {
//	    if (glfwGetKey(GLFW_KEY_SPACE) || firstrun == GL_TRUE) {
//            firstrun = GL_FALSE;
//            if (hasrun == GL_FALSE) {
//                hasrun = GL_TRUE;
//                runAlgorithm(pyramid, pyramid_x, pyramid_y, pyramid_u, example, matches_x, matches_y);
//				glViewport(0,0,512,512);
//            }
//        } else {
//            hasrun = GL_FALSE;
//        }

//		for (unsigned int i = 0; i<10; ++i) {
//			if (glfwGetKey('0'+i)) {
//				glUniform1i(tex,0);
//				glActiveTexture(GL_TEXTURE0);
//				glBindTexture(GL_TEXTURE_2D, (set==0?pyramid[i]:(set==1?pyramid_u[i]:(set==2?pyramid_x[i]:pyramid_y[i]))));
//				glUniform1i(exemplar,1);
//				glActiveTexture(GL_TEXTURE1);
//				glBindTexture(GL_TEXTURE_2D, example);
//			}
//		}
//		if (glfwGetKey(GLFW_KEY_F1)) {
//			glUniform1i(mode, 0);
//            glActiveTexture(GL_TEXTURE1);
//            glBindTexture(GL_TEXTURE_2D, example);
//		}
//		if (glfwGetKey(GLFW_KEY_F2)) {
//			glUniform1i(mode, 1);
//            glActiveTexture(GL_TEXTURE1);
//            glBindTexture(GL_TEXTURE_2D, example);
//		}
//		if (glfwGetKey(GLFW_KEY_F3)) {
//			glUniform1i(mode, 2);
//            glActiveTexture(GL_TEXTURE1);
//            glBindTexture(GL_TEXTURE_2D, example);
//		}
//        if (glfwGetKey(GLFW_KEY_F5)) {
//            set = 0;
//        }
//        if (glfwGetKey(GLFW_KEY_F6)) {
//            set = 1;
//        }
//        if (glfwGetKey(GLFW_KEY_F7)) {
//            set = 2;
//        }
//        if (glfwGetKey(GLFW_KEY_F8)) {
//            set=3;
//        }
//		if (glfwGetKey(GLFW_KEY_F9)) {
//			glUniform1i(mode, 2);
//            glActiveTexture(GL_TEXTURE1);
//            glBindTexture(GL_TEXTURE_2D, matches_x);
//		}
//		if (glfwGetKey(GLFW_KEY_F10)) {
//			glUniform1i(mode, 2);
//            glActiveTexture(GL_TEXTURE1);
//            glBindTexture(GL_TEXTURE_2D, matches_y);
//		}
//		if (glfwGetKey(GLFW_KEY_F11)) {
//			glUniform1i(mode, 3);
//            glActiveTexture(GL_TEXTURE1);
//            glBindTexture(GL_TEXTURE_2D, example);
//		}
        // OpenGL rendering goes here...
		glClear( GL_COLOR_BUFFER_BIT );
		// draw the triangle
		glBindVertexArray(vertexArrayID);
		glDrawArrays(GL_TRIANGLE_STRIP,0,4);
		// Swap front and back rendering buffers
        glfwSwapBuffers();
		// Check if ESC key was pressed or window was closed
        cv::Mat timg(512, 512, CV_8UC3);
        glReadPixels(0, 0, timg.cols, timg.rows, GL_BGR, GL_UNSIGNED_BYTE, timg.data);
        cv::imwrite("fuck.png", timg);
        running = GL_FALSE;

		running = !glfwGetKey( GLFW_KEY_ESC ) && glfwGetWindowParam( GLFW_OPENED );
	}
	// Close window and terminate GLFW
	glfwTerminate();
	// Exit program
	exit( EXIT_SUCCESS );
}
