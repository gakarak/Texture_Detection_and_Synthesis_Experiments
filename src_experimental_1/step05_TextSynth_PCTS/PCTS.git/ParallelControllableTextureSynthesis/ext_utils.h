#ifndef EXT_UTILS_H
#define EXT_UTILS_H

#include <cstddef>
#include <vector>

#include <opencv2/imgproc.hpp>
#include <opencv2/highgui.hpp>

void showMat(const cv::Mat& pimg, std::string winName="win", bool isBlockInput=true);
double Vec3bDiff(const cv::Vec3b& v1, const cv::Vec3b& v2);

template <class T>
class dynamicArray2D
{
public:
    dynamicArray2D() : rows(0), cols(0)
    {
    }
    dynamicArray2D(int row, int col) : rows(row), cols(col)
    {
        this->data.resize(this->cols*this->rows);
    }
//    T& operator()(int row, int column)
//    {
//        if (rows < row)
//        {
//            rows = row;
//            data.resize(rows * cols);
//        }
//        else if (cols < column)
//        {
//            cols = column;
//            data.resize(rows * cols);
//        }
//        return data[row * cols + column];
//    }
//    T operator()(int row, int column) const
//    {
//        if (rows < row)
//        {
//            rows = row;
//            data.resize(rows * cols);
//        }
//        else if (cols < column)
//        {
//            cols = column;
//            data.resize(rows * cols);
//        }
//        return data[row * cols + column];
//    }
    T& at(int row, int column) {
//        return this->operator () (row, column);
        if (row < 0 || row >= rows
            || column < 0 || column >= cols){
          return data.at(-1*(row * cols + column));
        }
        return data[row * cols + column];
    }
public:
    int rows;
    int cols;
private:
    std::vector<T> data;
};

#endif // EXT_UTILS_H
