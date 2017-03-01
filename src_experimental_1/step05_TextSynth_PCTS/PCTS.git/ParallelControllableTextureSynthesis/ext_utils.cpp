#include "ext_utils.h"

#include <iostream>
#include <sstream>

#include <opencv2/imgproc.hpp>

void showMat(const cv::Mat &pimg, std::string winName, bool isBlockInput) {
    std::vector<cv::Mat> lstChannels;

    cv::Mat tmp = pimg;

    /*if (pimg.rows < 100 || pimg.cols < 100){
      cv::resize(pimg, tmp, cv::Size(512, 512), 0, 0, cv::INTER_NEAREST);
    }*/
//    cv::normalize(pimg, tmp, 0, 255, CV_MINMAX, CV_8U);
    cv::imshow(winName, tmp);

    /*
    cv::split(pimg, lstChannels);
    std::cout << pimg << std::endl;
    std::cout << "type:" << pimg.type() << " / depth = " << pimg.depth() << std::endl;
    for(int chi=0; chi<lstChannels.size(); chi++) {
        cv::Mat tmp;
        cv::normalize(lstChannels.at(chi), tmp, 0, 255, CV_MINMAX, CV_8U);
        std::stringstream ss;
        ss << "win_" << chi;
        cv::imshow(ss.str(), tmp);
    }
    */

    if(isBlockInput) {
        cv::waitKey(0);
    }
}

double Vec3bDiff(const cv::Vec3b &v1, const cv::Vec3b &v2) {
    //TODO: For DEBUG -> local variable declaration
    double tret = cv::norm(v1, v2, CV_L2);
    return tret;
}
