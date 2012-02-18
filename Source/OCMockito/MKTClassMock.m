//
//  OCMockito - MKTClassMock.m
//  Copyright 2011 Jonathan M. Reid. See LICENSE.txt
//

#import "MKTClassMock.h"

#import "MKTInvocationContainer.h"
#import "MKTInvocationMatcher.h"
#import "MKMockingProgress.h"
#import "MKOngoingStubbing.h"
#import "MKVerificationData.h"
#import "MKVerificationMode.h"


@interface MKTClassMock ()
@property(nonatomic, assign) Class mockedClass;
@property(nonatomic, retain) MKMockingProgress *mockingProgress;
@property(nonatomic, retain) MKTInvocationContainer *invocationContainer;
@end


@implementation MKTClassMock

@synthesize mockedClass;
@synthesize mockingProgress;
@synthesize invocationContainer;

+ (id)mockForClass:(Class)aClass
{
    return [[[self alloc] initWithClass:aClass] autorelease];
}

- (id)initWithClass:(Class)aClass
{
    if (self)
    {
        mockedClass = aClass;
        mockingProgress = [[MKMockingProgress sharedProgress] retain];
        invocationContainer = [[MKTInvocationContainer alloc] initWithMockingProgress:mockingProgress];
    }
    return self;
}

- (void)dealloc
{
    [mockingProgress release];
    [invocationContainer release];
    [super dealloc];
}

#define HANDLE_METHOD_RETURN_TYPE(type, typeName)                                           \
    else if (strcmp(methodReturnType, @encode(type)) == 0)                                  \
    {                                                                                       \
        type answer = [[invocationContainer findAnswerFor:anInvocation] typeName ## Value]; \
        [anInvocation setReturnValue:&answer];                                              \
    }

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    id <MKVerificationMode> verificationMode = [mockingProgress pullVerificationMode];
    if (verificationMode)
    {
        MKTInvocationMatcher *invocationMatcher = [mockingProgress pullInvocationMatcher];
        if (!invocationMatcher)
            invocationMatcher = [[[MKTInvocationMatcher alloc] init] autorelease];
        [invocationMatcher setExpectedInvocation:anInvocation];
        
        MKVerificationData *data = [[MKVerificationData alloc] init];
        [data setInvocations:invocationContainer];
        [data setWanted:invocationMatcher];
        [data setTestLocation:[mockingProgress testLocation]];
        [verificationMode verifyData:data];
        
        [data release];
        return;
    }
    
    [invocationContainer setInvocationForPotentialStubbing:anInvocation];
    MKOngoingStubbing *ongoingStubbing = [[MKOngoingStubbing alloc]
                                          initWithInvocationContainer:invocationContainer];
    [mockingProgress reportOngoingStubbing:ongoingStubbing];
    [ongoingStubbing release];
    
    NSMethodSignature *methodSignature = [anInvocation methodSignature];
    const char* methodReturnType = [methodSignature methodReturnType];
    if (strcmp(methodReturnType, @encode(id)) == 0)
    {
        id answer = [invocationContainer findAnswerFor:anInvocation];
        [anInvocation setReturnValue:&answer];
    }
    HANDLE_METHOD_RETURN_TYPE(char, char)
    HANDLE_METHOD_RETURN_TYPE(int, int)
    HANDLE_METHOD_RETURN_TYPE(short, short)
    HANDLE_METHOD_RETURN_TYPE(long, long)
    HANDLE_METHOD_RETURN_TYPE(long long, longLong)
    HANDLE_METHOD_RETURN_TYPE(unsigned char, unsignedChar)
    HANDLE_METHOD_RETURN_TYPE(unsigned int, unsignedInt)
    HANDLE_METHOD_RETURN_TYPE(unsigned short, unsignedShort)
    HANDLE_METHOD_RETURN_TYPE(unsigned long, unsignedLong)
    HANDLE_METHOD_RETURN_TYPE(unsigned long long, unsignedLongLong)
    HANDLE_METHOD_RETURN_TYPE(float, float)
    HANDLE_METHOD_RETURN_TYPE(double, double)
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    return [mockedClass instanceMethodSignatureForSelector:aSelector];
}


#pragma mark - NSObject

- (BOOL)respondsToSelector:(SEL)aSelector
{
    return [mockedClass instancesRespondToSelector:aSelector];
}


#pragma mark - MTPrimitiveArgumentMatching

- (id)withMatcher:(id <HCMatcher>)matcher forArgument:(NSUInteger)index
{
    [mockingProgress setMatcher:matcher forArgument:index];
    return self;
}

- (id)withMatcher:(id <HCMatcher>)matcher
{
    return [self withMatcher:matcher forArgument:0];
}

@end