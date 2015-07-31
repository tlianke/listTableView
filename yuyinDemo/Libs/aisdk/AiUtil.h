//
//  AiUtil.h
//  AiEngineLib
//
//  Created by Midfar Sun on 3/10/14.
//  Copyright (c) 2013 Midfar Sun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AiUtil : NSObject

/**
 * 计算字符串的SHA1值
 */
+(NSString *)sha1:(NSString *)str;

/**
 * 计算文件的MD5值
 */
+(NSString *)md5:(NSString *)path;

/**
 * 获得英文句子中，单词数组
 */
+(NSArray *)getWordArray:(NSString *)string;

/**
 * 计算英文句子中，单词的个数
 */
+(NSInteger)getWordCount:(NSString *)string;

/**
 * 计算中文句子中，汉字的个数
 */
+(NSInteger)getHanziCount:(NSString *)pin1yin1;

/**
 * 获取应用缓存地址
 */
+(NSString *)cachePath;

/**
 * 解压zip文件
 * @return 解压后的目录
 */
+(NSString *)unzipFile:(NSString *)filePath;

@end
