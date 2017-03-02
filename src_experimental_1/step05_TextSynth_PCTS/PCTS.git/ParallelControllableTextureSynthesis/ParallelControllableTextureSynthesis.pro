TEMPLATE = app
CONFIG += console c++11
CONFIG -= app_bundle
CONFIG -= qt

unix {
    INCLUDEPATH += /home/pisarik/Libs/opencv-3.1.0-build-release/include
    LIBS += -L/home/pisarik/Libs/opencv-3.1.0-build-release/lib -lopencv_aruco -lopencv_bgsegm -lopencv_bioinspired -lopencv_calib3d -lopencv_ccalib -lopencv_core -lopencv_datasets -lopencv_dnn -lopencv_dpm -lopencv_face -lopencv_features2d -lopencv_flann -lopencv_fuzzy -lopencv_hdf -lopencv_highgui -lopencv_imgcodecs -lopencv_imgproc -lopencv_line_descriptor -lopencv_ml -lopencv_objdetect -lopencv_optflow -lopencv_photo -lopencv_plot -lopencv_reg -lopencv_rgbd -lopencv_saliency -lopencv_shape -lopencv_stereo -lopencv_stitching -lopencv_structured_light -lopencv_superres -lopencv_surface_matching -lopencv_text -lopencv_tracking -lopencv_videoio -lopencv_video -lopencv_videostab -lopencv_xfeatures2d -lopencv_ximgproc -lopencv_xobjdetect -lopencv_xphoto

    QMAKE_CXXFLAGS += -fopenmp
    QMAKE_LFLAGS   += -fopenmp
    LIBS += -fopenmp
}

win32{
    QMAKE_CXXFLAGS += -openmp
    QMAKE_LFLAGS   += -openmp

    CONFIG( debug, debug|release ) {
        INCLUDEPATH += C:\Local\Programming\CPP_Libraries\OpenCV\build_x64_12\install\x64\vc12\include
        LIBS += -LC:\Local\Programming\CPP_Libraries\OpenCV\build_x64_12\install\x64\vc12\lib \
            -lopencv_aruco320d \
            -lopencv_bgsegm320d \
            -lopencv_bioinspired320d \
            -lopencv_calib3d320d \
            -lopencv_ccalib320d \
            -lopencv_core320d \
            -lopencv_datasets320d \
            -lopencv_dnn320d \
            -lopencv_dpm320d \
            -lopencv_face320d \
            -lopencv_features2d320d \
            -lopencv_flann320d \
            -lopencv_fuzzy320d \
            -lopencv_highgui320d \
            -lopencv_imgcodecs320d \
            -lopencv_imgproc320d \
            -lopencv_line_descriptor320d \
            -lopencv_ml320d \
            -lopencv_objdetect320d \
            -lopencv_optflow320d \
            -lopencv_phase_unwrapping320d \
            -lopencv_photo320d \
            -lopencv_plot320d \
            -lopencv_reg320d \
            -lopencv_rgbd320d \
            -lopencv_saliency320d \
            -lopencv_shape320d \
            -lopencv_stereo320d \
            -lopencv_stitching320d \
            -lopencv_structured_light320d \
            -lopencv_superres320d \
            -lopencv_surface_matching320d \
            -lopencv_text320d \
            -lopencv_tracking320d \
            -lopencv_videoio320d \
            -lopencv_video320d \
            -lopencv_videostab320d \
            -lopencv_xfeatures2d320d \
            -lopencv_ximgproc320d \
            -lopencv_xobjdetect320d \
            -lopencv_xphoto320d
    }
    else {
        INCLUDEPATH += C:\Local\Programming\CPP_Libraries\OpenCV\build_x64_12\install\x64\vc12\include
        LIBS += -LC:\Local\Programming\CPP_Libraries\OpenCV\build_x64_12\install\x64\vc12\lib \
            -lopencv_aruco320 \
            -lopencv_bgsegm320 \
            -lopencv_bioinspired320 \
            -lopencv_calib3d320 \
            -lopencv_ccalib320 \
            -lopencv_core320 \
            -lopencv_datasets320 \
            -lopencv_dnn320 \
            -lopencv_dpm320 \
            -lopencv_face320 \
            -lopencv_features2d320 \
            -lopencv_flann320 \
            -lopencv_fuzzy320 \
            -lopencv_highgui320 \
            -lopencv_imgcodecs320 \
            -lopencv_imgproc320 \
            -lopencv_line_descriptor320 \
            -lopencv_ml320 \
            -lopencv_objdetect320 \
            -lopencv_optflow320 \
            -lopencv_phase_unwrapping320 \
            -lopencv_photo320 \
            -lopencv_plot320 \
            -lopencv_reg320 \
            -lopencv_rgbd320 \
            -lopencv_saliency320 \
            -lopencv_shape320 \
            -lopencv_stereo320 \
            -lopencv_stitching320 \
            -lopencv_structured_light320 \
            -lopencv_superres320 \
            -lopencv_surface_matching320 \
            -lopencv_text320 \
            -lopencv_tracking320 \
            -lopencv_videoio320 \
            -lopencv_video320 \
            -lopencv_videostab320 \
            -lopencv_xfeatures2d320 \
            -lopencv_ximgproc320 \
            -lopencv_xobjdetect320 \
            -lopencv_xphoto320
    }
}

SOURCES += main.cpp \
           ParallelControllableTextureSynthesis.cpp \
           ext_utils.cpp

HEADERS += \
    ParallelControllableTextureSynthesis.h \
    ext_utils.h
