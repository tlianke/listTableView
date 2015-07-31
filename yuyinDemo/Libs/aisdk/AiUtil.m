//
//  AiUtil.m
//  AiEngineLib
//
//  Created by Midfar Sun on 3/10/14.
//  Copyright (c) 2013 Midfar Sun. All rights reserved.
//

#import "AiUtil.h"
#import "SSZipArchive.h"
#import <CommonCrypto/CommonDigest.h>

#if !__has_feature(objc_arc)
#error "This source file must be compiled with ARC enabled!"
#endif

@implementation AiUtil

+ (NSString *)sha1:(NSString *)str
{
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    
    CC_SHA1(data.bytes, (CC_LONG)data.length, digest);
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
    {
        [output appendFormat:@"%02x", digest[i]];
    }
    
    return output;
}

+(NSString *)md5:(NSString *)path
{
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:path];
    if( handle == nil ) {
        return nil;
    }
    CC_MD5_CTX md5;
    CC_MD5_Init(&md5);
    BOOL done = NO;
    while(!done)
    {
        NSData* fileData = [handle readDataOfLength: 10240 ];
        CC_MD5_Update(&md5, [fileData bytes], (CC_LONG)[fileData length]);
        if( [fileData length] == 0 ) done = YES;
    }
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final(digest, &md5);
    NSString* s = [NSString stringWithFormat: @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                   digest[0], digest[1],
                   digest[2], digest[3],
                   digest[4], digest[5],
                   digest[6], digest[7],
                   digest[8], digest[9],
                   digest[10], digest[11],
                   digest[12], digest[13],
                   digest[14], digest[15]];
    
    return s;
}

+(NSArray *)getWordArray:(NSString *)string
{
    NSCharacterSet *separators = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSArray *words = [string componentsSeparatedByCharactersInSet:separators];
    NSMutableArray *wordArr = [NSMutableArray arrayWithArray:words];
    for (NSInteger i=[wordArr count]-1; i>=0; i--) {
        if ([@"" isEqualToString:[wordArr objectAtIndex:i]]) {
            [wordArr removeObjectAtIndex:i];
        }
    }
    return wordArr;
}

+(NSInteger)getWordCount:(NSString *)string
{
    NSCharacterSet *separators = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSArray *words = [string componentsSeparatedByCharactersInSet:separators];
    
    NSIndexSet *separatorIndexes = [words indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return [obj isEqualToString:@""];
    }];
    
    return [words count] - [separatorIndexes count];
}

+(NSInteger)getHanziCount:(NSString *)pin1yin1
{
    return [[pin1yin1 componentsSeparatedByString:@"-"] count];
}

+(NSString *)cachePath
{
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    return path;
}

+(NSString *)unzipFile:(NSString *)filePath
{
    NSString *md5sum = [AiUtil md5:filePath];
    NSString *fileName = [filePath lastPathComponent];
    NSString *pureName = [fileName substringToIndex:fileName.length-[fileName pathExtension].length-1];
    NSString *targetDir = [[AiUtil cachePath] stringByAppendingPathComponent:pureName];
    BOOL isDir = NO;
    BOOL isDirExist = [[NSFileManager defaultManager] fileExistsAtPath:targetDir isDirectory:&isDir];
    NSString *md5sumFilePath = [targetDir stringByAppendingPathComponent:@".md5sum"];
    if (isDir && isDirExist) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:md5sumFilePath]) {
            NSString *md5sum2 = [NSString stringWithContentsOfFile:md5sumFilePath encoding:NSUTF8StringEncoding error:nil];
            if ([md5sum2 isEqualToString:md5sum]) {// already extracted
                return targetDir;
            }
        }
    }
    // remove old dirty resource
    if (isDirExist) {
        [[NSFileManager defaultManager] removeItemAtPath:targetDir error:nil];
    }
    [[NSFileManager defaultManager] createDirectoryAtPath:targetDir withIntermediateDirectories:YES attributes:nil error:nil];
    BOOL b = [SSZipArchive unzipFileAtPath:filePath toDestination:targetDir];
    if (b) {
        [md5sum writeToFile:md5sumFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        return targetDir;
    }
    return nil;
}

@end
