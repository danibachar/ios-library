/* Copyright Airship and Contributors */

#import "UATagGroupsMutation+Internal.h"

#define kUATagGroupsSetKey @"set"
#define kUATagGroupsAddKey @"add"
#define kUATagGroupsRemoveKey @"remove"

#if __has_include("AirshipCore/AirshipCore-Swift.h")
#import <AirshipCore/AirshipCore-Swift.h>
#elif __has_include("Airship/Airship-Swift.h")
#import <Airship/Airship-Swift.h>
#endif


@interface UATagGroupsMutation()
@property(nonatomic, copy) NSDictionary<NSString *, NSSet<NSString *> *> *addTagGroups;
@property(nonatomic, copy) NSDictionary<NSString *, NSSet<NSString *> *> *removeTagGroups;
@property(nonatomic, copy) NSDictionary<NSString *, NSSet<NSString *> *> *setTagGroups;
@end

@implementation UATagGroupsMutation

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.addTagGroups forKey:kUATagGroupsAddKey];
    [coder encodeObject:self.removeTagGroups forKey:kUATagGroupsRemoveKey];
    [coder encodeObject:self.setTagGroups forKey:kUATagGroupsSetKey];
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    
    if (self) {
        self.addTagGroups = [coder decodeObjectOfClass:[NSDictionary class] forKey:kUATagGroupsAddKey];
        self.removeTagGroups = [coder decodeObjectOfClass:[NSDictionary class] forKey:kUATagGroupsRemoveKey];
        self.setTagGroups = [coder decodeObjectOfClass:[NSDictionary class] forKey:kUATagGroupsSetKey];
    }

    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

+ (instancetype)mutationToAddTags:(NSArray *)tags group:(NSString *)group {

    UATagGroupsMutation *mutation = [[UATagGroupsMutation alloc] init];

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:[NSSet setWithArray:tags] forKey:group];
    mutation.addTagGroups = dictionary;

    return mutation;
}

+ (instancetype)mutationToRemoveTags:(NSArray *)tags group:(NSString *)group {

    UATagGroupsMutation *mutation = [[UATagGroupsMutation alloc] init];

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:[NSSet setWithArray:tags] forKey:group];
    mutation.removeTagGroups = dictionary;

    return mutation;
}

+ (instancetype)mutationToSetTags:(NSArray *)tags group:(NSString *)group {

    UATagGroupsMutation *mutation = [[UATagGroupsMutation alloc] init];

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:[NSSet setWithArray:tags] forKey:group];
    mutation.setTagGroups = dictionary;

    return mutation;
}

+ (instancetype)mutationWithAddTags:(NSDictionary *)addTags
                         removeTags:(NSDictionary *)removeTags {

    UATagGroupsMutation *mutation = [[UATagGroupsMutation alloc] init];
    mutation.removeTagGroups = [UATagGroupsMutation normalizeTagGroup:removeTags];
    mutation.addTagGroups = [UATagGroupsMutation normalizeTagGroup:addTags];;
    return mutation;
}

- (NSDictionary *)payload {
    NSMutableDictionary *payload = [NSMutableDictionary dictionary];
    if (self.setTagGroups.count) {
        [payload setValue:[UATagGroupsMutation prepareTagGroup:self.setTagGroups] forKey:kUATagGroupsSetKey];
    }

    if (self.addTagGroups.count) {
        [payload setValue:[UATagGroupsMutation prepareTagGroup:self.addTagGroups] forKey:kUATagGroupsAddKey];
    }

    if (self.removeTagGroups.count) {
        [payload setValue:[UATagGroupsMutation prepareTagGroup:self.removeTagGroups] forKey:kUATagGroupsRemoveKey];
    }

    return [payload copy];
}

- (NSMutableSet *)mutableTagSet:(id)collection {
    return [collection isKindOfClass:[NSSet class]] ? [(NSArray *)collection mutableCopy] : [NSMutableSet setWithArray:(NSArray *)collection];
}

- (NSDictionary *)applyToTagGroups:(NSDictionary *)tagGroups {
    NSMutableDictionary *tagGroupsCopy = [tagGroups mutableCopy];

    if (self.addTagGroups.count) {
        for (NSString *group in self.addTagGroups) {
            NSMutableSet *tagSet = [self mutableTagSet:tagGroupsCopy[group]];

            for (NSString *tag in self.addTagGroups[group]) {
                [tagSet addObject:tag];
            }

            tagGroupsCopy[group] = tagSet;
        }
    }

    if (self.removeTagGroups.count) {
        for (NSString *group in self.removeTagGroups) {
            NSMutableSet *tagSet = [self mutableTagSet:tagGroupsCopy[group]];

            for (NSString *tag in self.removeTagGroups[group]) {
                [tagSet removeObject:tag];
            }

            tagGroupsCopy[group] = tagSet;
        }
    }

    if (self.setTagGroups.count) {
        for (NSString *group in self.setTagGroups) {
            tagGroupsCopy[group] = self.setTagGroups[group];
        }
    }

    return tagGroupsCopy;
}

+ (NSArray<UATagGroupsMutation *> *)collapseMutations:(NSArray<UATagGroupsMutation *> *)mutations {
    if (!mutations.count) {
        return mutations;
    }

    NSMutableDictionary *addTagGroups = [NSMutableDictionary dictionary];
    NSMutableDictionary *removeTagGroups = [NSMutableDictionary dictionary];
    NSMutableDictionary *setTagGroups = [NSMutableDictionary dictionary];

    for (UATagGroupsMutation *mutation in mutations) {

        // Add tags
        for (NSString *group in mutation.addTagGroups) {

            NSMutableSet *tags = [mutation.addTagGroups[group] mutableCopy];

            // Add to the set tag groups if we can
            if (setTagGroups[group]) {
                [setTagGroups[group] unionSet:tags];
                continue;
            }

            // Remove from remove tag groups
            [removeTagGroups[group] minusSet:tags];
            if (![removeTagGroups[group] count]) {
                [removeTagGroups removeObjectForKey:group];
            }

            // Add to the add tag groups
            if (!addTagGroups[group]) {
                addTagGroups[group] = tags;
            } else {
                [addTagGroups[group] unionSet:tags];
            }
        }

        // Remove tags
        for (NSString *group in mutation.removeTagGroups) {
            NSMutableSet *tags = [mutation.removeTagGroups[group] mutableCopy];

            // Remove to the set tag groups if we can
            if (setTagGroups[group]) {
                [setTagGroups[group] minusSet:tags];
                break;
            }

            // Remove from add tag groups
            [addTagGroups[group] minusSet:tags];
            if (![addTagGroups[group] count]) {
                [addTagGroups removeObjectForKey:group];
            }

            // Add to the remove tag groups
            if (!removeTagGroups[group]) {
                removeTagGroups[group] = tags;
            } else {
                [removeTagGroups[group] unionSet:tags];
            }
        }

        // Set tags
        for (NSString *group in mutation.setTagGroups) {

            NSMutableSet *tags = [mutation.setTagGroups[group] mutableCopy];

            // Add to the set tags group
            setTagGroups[group] = tags;

            // Remove from the other groups
            [removeTagGroups removeObjectForKey:group];
            [addTagGroups removeObjectForKey:group];
        }
    }

    NSMutableArray *collapsedMutations = [NSMutableArray array];

    // Set must be a separate mutation
    if (setTagGroups.count) {
        UATagGroupsMutation *mutation = [[UATagGroupsMutation alloc] init];
        mutation.setTagGroups = setTagGroups;
        [collapsedMutations addObject:mutation];
    }

    // Add and remove can be collapsed into one mutation
    if (addTagGroups.count || removeTagGroups.count) {
        UATagGroupsMutation *mutation = [[UATagGroupsMutation alloc] init];
        mutation.removeTagGroups = removeTagGroups;
        mutation.addTagGroups = addTagGroups;
        [collapsedMutations addObject:mutation];
    }

    return [collapsedMutations copy];
}

/**
 * Normalizes a dictionary of tag groups. Converts any arrays to sets.
 * @param tagGroups A tag group.
 * @returns A tag group with sets instead of arrays.
 */
+ (NSDictionary *)normalizeTagGroup:(NSDictionary *)tagGroups {
    if (!tagGroups.count) {
        return nil;
    }

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    for (NSString *group in tagGroups) {

        NSSet *tags = nil;
        if ([tagGroups[group] isKindOfClass:[NSSet class]]) {
            tags = tagGroups[group];
        } else {
            tags = [NSSet setWithArray:tagGroups[group]];
        }

        [dictionary setValue:tags forKey:group];
    }

    return dictionary;
}


/**
 * Converts a dictionary of string to set to a dictionary of string to array.
 * @param tagGroups A tag group.
 * @returns A tag group with arrays instead of sets.
 */
+ (NSDictionary *)prepareTagGroup:(NSDictionary *)tagGroups {
    if (!tagGroups.count) {
        return nil;
    }

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    for (NSString *group in tagGroups) {

        NSArray *tags = nil;
        if ([tagGroups[group] isKindOfClass:[NSSet class]]) {
            tags = [tagGroups[group] allObjects];
        } else {
            tags = tagGroups[group];
        }

        [dictionary setValue:tags forKey:group];
    }

    return dictionary;
}

- (BOOL)isEqualToMutation:(UATagGroupsMutation *)mutation {
    if (self.addTagGroups != mutation.addTagGroups && ![self.addTagGroups isEqualToDictionary:mutation.addTagGroups]) {
        return NO;
    }

    if (self.removeTagGroups != mutation.removeTagGroups && ![self.removeTagGroups isEqualToDictionary:mutation.removeTagGroups]) {
        return NO;
    }

    if (self.setTagGroups != mutation.setTagGroups && ![self.setTagGroups isEqualToDictionary:mutation.setTagGroups]) {
        return NO;
    }

    return YES;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }

    if (![object isKindOfClass:[self class]]) {
        return NO;
    }

    return [self isEqualToMutation:object];
}

- (NSUInteger)hash {
    NSUInteger result = 1;
    result = 31 * result + [self.addTagGroups hash];
    result = 31 * result + [self.removeTagGroups hash];
    result = 31 * result + [self.setTagGroups hash];
    return result;
}

- (NSArray<UATagGroupUpdate *> *)tagGroupUpdates {
    NSMutableArray *updates = [NSMutableArray array];
    for (NSString *group in self.addTagGroups.allKeys) {
        UATagGroupUpdate *update = [[UATagGroupUpdate alloc] initWithGroup:group
                                                                      tags:self.addTagGroups[group].allObjects
                                                                      type:UATagGroupUpdateTypeAdd];
        [updates addObject:update];
    }
    
    for (NSString *group in self.removeTagGroups.allKeys) {
        UATagGroupUpdate *update = [[UATagGroupUpdate alloc] initWithGroup:group
                                                                      tags:self.removeTagGroups[group].allObjects
                                                                      type:UATagGroupUpdateTypeRemove];
        [updates addObject:update];
    }
    
    
    for (NSString *group in self.setTagGroups.allKeys) {
        UATagGroupUpdate *update = [[UATagGroupUpdate alloc] initWithGroup:group
                                                                      tags:self.setTagGroups[group].allObjects
                                                                      type:UATagGroupUpdateTypeSet];
        [updates addObject:update];
    }
    
    return updates;
}

@end
