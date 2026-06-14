////////////////////////////////////////////////////////////////////////////////////////////////
// LZSS 压缩程序
////////////////////////////////////////////////////////////////////////////////////////////////
/*
 一、压缩数据，本程序提供了三个压缩入口，格式如下：
 
 unsigned long Compress(unsigned char *InData,unsigned long Size,unsigned char *OutData)
 输入数据：InData，压缩前的数据内存指针
 　　　　　Size，压缩前的数据长度，以字节为单位
 　　　　　OutData，压缩后保存数据用的内存指针(必须是已分配好内存了)
 输出数据：压缩后的数据长度，以字节为单位
 
 unsigned long Compress(unsigned char *InData,unsigned long Size,FILE *OutFile)
 输入数据：InData，压缩前的数据内存指针
 　　　　　Size，压缩前的数据长度，以字节为单位
 　　　　　OutFile，压缩后用于数据输出的文件指针
 输出数据：压缩后的数据长度，以字节为单位
 
 unsigned long Compress(FILE *InFile,unsigned long Size,FILE *OutFile)
 输入数据：InFile，压缩前的文件指针
 　　　　　Size，压缩前的数据长度，以字节为单位
 　　　　　OutFile，压缩后用于数据输出的文件指针
 输出数据：压缩后的数据长度，以字节为单位
 
 二、解压数据，同压缩入口一样，本程序提供三个解压入口，格式如下：
 
 unsigned long UnCompress(unsigned char *InData,unsigned long Size,unsigned char *OutData)
 输入数据：InData，解压前的数据内存指针
 　　　　　Size，解压前的数据长度，以字节为单位
 　　　　　OutData，解压后保存数据用的内存指针(必须是已分配好内存了)
 输出数据：解压后的数据长度，以字节为单位
 
 unsigned long UnCompress(FILE *InFile,unsigned long Size,unsigned char *OutData)
 输入数据：InFile，解压前的文件指针
 　　　　　Size，解压前的数据长度，以字节为单位
 　　　　　OutData，解压后保存数据用的内存指针(必须是已分配好内存了)
 输出数据：解压后的数据长度，以字节为单位
 
 unsigned long UnCompress(FILE *InFile,unsigned long Size,FILE *OutFile)
 输入数据：InFile，解压前的文件指针
 　　　　　Size，解压前的数据长度，以字节为单位
 　　　　　OutData，解压后用于数据输出的文件指针
 输出数据：解压后的数据长度，以字节为单位
 */

#ifndef _LZSS_H_
#define _LZSS_H_

class LZSS
{
    enum LZSSDATA
    {
        inMEM=1,inFILE
    };
    unsigned char *buffer;
    int mpos,mlen;
    int *lson,*rson,*dad;
    
    unsigned char InType,OutType;                          //输入输出数据类型,指明是文件还是内存中的数据
    unsigned char *InData,*OutData;                        //输入输出数据指针
    FILE *fpIn,*fpOut;                                     //输入输出文件指针
    unsigned long InDataSize;                              //输入数据长度
    unsigned long InSize,OutSize;                          //已输入输出数据长度
    int GetByte();                                         //获取一个字节的数据
    void PutByte(unsigned char);                           //写入一个字节的数据
    
    void InitTree();					//初始化串表
    void InsertNode(int);					//插入一个表项
    void DeleteNode(int);					//删除一个表项
    void Encode();                                         //压缩数据
    void Decode();                                         //解压数据
public:
    LZSS();                                                //本类构造函数
    ~LZSS();                                               //本类析构函数
    unsigned long Compress(unsigned char *,unsigned long, unsigned char *);               //内存中的数据压缩
    unsigned long Compress(unsigned char *,unsigned long, FILE *);                        //将内存中的数据压缩后写入文件
    unsigned long Compress(FILE *,unsigned long,FILE *);   //压缩文件
    unsigned long UnCompress(unsigned char *,unsigned long, unsigned char *);             //内存中的数据解压
    unsigned long UnCompress(FILE *,unsigned long, unsigned char *);             //将文件中的数据解压后写入内存
    unsigned long UnCompress(FILE *,unsigned long,FILE *); //解压文件
};

#endif //_LZSS_H_

