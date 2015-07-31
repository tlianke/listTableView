//
//  JSONKit2.h
//

////////////
#pragma mark Deserializing methods
////////////
#import <UIKit/UIKit.h>

@interface NSString (JSONKitDeserializing2)
- (id)objectFromJSONString2;
@end

@interface NSData (JSONKitDeserializing2)
// The NSData MUST be UTF8 encoded JSON.
- (id)objectFromJSONData2;
@end

////////////
#pragma mark Serializing methods
////////////
  
@interface NSString (JSONKitSerializing2)
// Convenience methods for those that need to serialize the receiving NSString (i.e., instead of having to serialize a NSArray with a single NSString, you can "serialize to JSON" just the NSString).
// Normally, a string that is serialized to JSON has quotation marks surrounding it, which you may or may not want when serializing a single string, and can be controlled with includeQuotes:
// includeQuotes:YES `a "test"...` -> `"a \"test\"..."`
// includeQuotes:NO  `a "test"...` -> `a \"test\"...`
- (NSData *)JSONData2;
@end

@interface NSArray (JSONKitSerializing2)
- (NSData *)JSONData2;
- (NSString *)JSONString2;
@end

@interface NSDictionary (JSONKitSerializing2)
- (NSData *)JSONData2;
- (NSString *)JSONString2;
@end