//
//  JSONKit2.m
//
#import <UIKit/UIKit.h>
@implementation NSString (JSONKitDeserializing2)
- (id)objectFromJSONString2
{
    NSData *jsonData = [self dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&error];
    if (jsonObject != nil && error == nil){
        return jsonObject;
    }
    return nil;
}
@end

@implementation NSData (JSONKitDeserializing2)
- (id)objectFromJSONData2
{
    NSError *error = nil;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:self options:NSJSONReadingAllowFragments error:&error];
    if (jsonObject != nil && error == nil){
        return jsonObject;
    }
    return nil;
}
@end

@implementation NSString (JSONKitSerializing2)
- (NSData *)JSONData2
{
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:NSJSONWritingPrettyPrinted error:&error];
    if (error==nil) {
        return jsonData;
    }
    return nil;
}
@end

@implementation NSArray (JSONKitSerializing2)
- (NSData *)JSONData2
{
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:NSJSONWritingPrettyPrinted error:&error];
    if (error==nil) {
        return jsonData;
    }
    return nil;
}

- (NSString *)JSONString2
{
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:NSJSONWritingPrettyPrinted error:&error];
    if (error==nil && jsonData!=nil) {
        NSString *s = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        s = [s stringByReplacingOccurrencesOfString:@"\n[ ]*" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, s.length)];
        return s;
    }
    return nil;
}
@end

@implementation NSDictionary (JSONKitSerializing2)
- (NSData *)JSONData2
{
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:NSJSONWritingPrettyPrinted error:&error];
    if (error==nil) {
        return jsonData;
    }
    return nil;
}

- (NSString *)JSONString2
{
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:NSJSONWritingPrettyPrinted error:&error];
    if (error==nil && jsonData!=nil) {
        NSString *s = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        s = [s stringByReplacingOccurrencesOfString:@"\n[ ]*" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, s.length)];
        return s;
    }
    return nil;
}
@end