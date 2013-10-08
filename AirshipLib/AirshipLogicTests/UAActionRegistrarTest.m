/*
 Copyright 2009-2013 Urban Airship Inc. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.

 2. Redistributions in binaryform must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided withthe distribution.

 THIS SOFTWARE IS PROVIDED BY THE URBAN AIRSHIP INC``AS IS'' AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 EVENT SHALL URBAN AIRSHIP INC OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
#import <XCTest/XCTest.h>
#import "UAActionRegistrar+Internal.h"

@interface UAActionRegistrarTest : XCTestCase
@property(nonatomic, strong)NSMutableDictionary *originalRegistryEntries;
@property(nonatomic, strong)NSMutableDictionary *originalAliases;

@end

@implementation UAActionRegistrarTest
UAActionRegistrar *registrar;

- (void)setUp {
    [super setUp];

    registrar = [UAActionRegistrar shared];

    // Store current actions to restore later
    self.originalRegistryEntries = (NSMutableDictionary *)[UAActionRegistrar shared].registeredActionEntries;
    self.originalAliases = (NSMutableDictionary *)[UAActionRegistrar shared].aliases;

    // Start with a new action registry
    [UAActionRegistrar shared].registeredActionEntries = [NSMutableDictionary dictionary];
}

- (void)tearDown {
    // Restore previous action registries
    [UAActionRegistrar shared].registeredActionEntries = self.originalRegistryEntries;
    [UAActionRegistrar shared].aliases = self.originalAliases;

    [super tearDown];
}

/**
 * Test registering an action several different ways
 */
- (void)testRegisterAction {
    UAAction *action = [[UAAction alloc] init];

    UAActionPredicate predicate = ^(UAActionArguments *args) {
        return YES;
    };

    // Only name
    [registrar registerAction:action name:@"some-action"];
    XCTAssertEqual((NSUInteger) 1, registrar.registeredActionEntries.count, @"Should have 1 action registry entries");
    [self validateActionIsRegistered:action name:@"some-action" alias:nil predicate:nil];

    // Name and alias
    [registrar registerAction:action name:@"some-action" alias:@"alias"];
    XCTAssertEqual((NSUInteger) 1, registrar.registeredActionEntries.count, @"Should have 1 action registry entries");
    XCTAssertNotNil([registrar.aliases valueForKey:@"alias"], "Registering the actin should add the alias");
    [self validateActionIsRegistered:action name:@"some-action" alias:@"alias" predicate:nil];

    // Name and predicate
    [registrar registerAction:action name:@"some-action" predicate:predicate];
    XCTAssertEqual((NSUInteger) 1, registrar.registeredActionEntries.count, @"Should have 1 action registry entries");
    [self validateActionIsRegistered:action name:@"some-action" alias:nil predicate:predicate];

    // Name, alias, and predicate
    [registrar registerAction:action name:@"some-action" alias:@"alias" predicate:predicate];
    XCTAssertEqual((NSUInteger) 1, registrar.registeredActionEntries.count, @"Should have 1 action registry entries");
    XCTAssertNotNil([registrar.aliases valueForKey:@"alias"], "Registering the actin should add the alias");
    [self validateActionIsRegistered:action name:@"some-action" alias:@"alias" predicate:predicate];

}

/**
 * Test that registering a nil action clears the registration for the action
 */
- (void)testRegisterNilAction {
    XCTAssertEqual((NSUInteger) 0, registrar.registeredActionEntries.count, @"Registering a nil action should not add an action registry");

    // Register an action
    UAAction *action = [[UAAction alloc] init];
    [registrar registerAction:action name:@"some-action" alias:@"alias"];
    XCTAssertEqual((NSUInteger) 1, registrar.registeredActionEntries.count, @"Should have 1 action registry entries");
    XCTAssertNotNil([registrar.aliases valueForKey:@"alias"], "Registering the actin should add the alias");

    // Clear the action by registering nil for the name
    [registrar registerAction:nil name:@"some-action"];
    XCTAssertEqual((NSUInteger) 0, registrar.registeredActionEntries.count, @"Registering a nil action should remove the action entry");

    // Should clear the alias for the entry
    XCTAssertNil([registrar.aliases valueForKey:@"alias"], "Registering a nil action should remove the old actions alias");
}

/**
 * Test registering an action with an alias that conflicts with other actions
 */
- (void)testReigsterActionConflictingAlias {
    UAAction *action = [[UAAction alloc] init];

    [registrar registerAction:action name:@"nameOne" alias:@"aliasOne"];
    [registrar registerAction:action name:@"nameTwo" alias:@"aliasTwo"];


    // Try to register an action with the name 'aliasOne' and alias 'aliasTwo'
    [registrar registerAction:action name:@"aliasOne" alias:@"aliasTwo"];

    // Should still have 3 entries
    XCTAssertEqual((NSUInteger) 3, registrar.registeredActionEntries.count, @"Registering conflicting actions aliases should not remove entries");

    // First and second registration entry should no longer have there aliases
    [self validateActionIsRegistered:action name:@"nameOne" alias:nil predicate:nil];
    [self validateActionIsRegistered:action name:@"nameTwo" alias:nil predicate:nil];

    // Verify third registration has the correct names
    [self validateActionIsRegistered:action name:@"aliasOne" alias:@"aliasTwo" predicate:nil];
}

/**
 * Test registering an action with an name that conflicts with other actions whose alias
 */
- (void)testReigsterActionConflictingName {
    UAAction *action = [[UAAction alloc] init];

    [registrar registerAction:action name:@"nameOne" alias:@"aliasOne"];
    [registrar registerAction:action name:@"nameTwo" alias:@"aliasTwo"];


    // Try to register an action with the name 'nameOne' and alias 'nameTwo'
    [registrar registerAction:action name:@"nameOne" alias:@"nameTwo"];

    // Should only have a one entry
    XCTAssertEqual((NSUInteger) 1, registrar.registeredActionEntries.count, @"Registering conflicting actions names should remove entries");

    // Verify third registration has the correct names
    [self validateActionIsRegistered:action name:@"nameOne" alias:@"nameTwo" predicate:nil];
}

/**
 * Test registryEntryForName: returns a registry entry whose name or alias matches
 */
- (void)testregistryEntryForName {
    UAAction *action = [[UAAction alloc] init];
    [registrar registerAction:action name:@"name" alias:@"alias"];

    XCTAssertNotNil([registrar registryEntryForName:@"name"], "RegistryEntry is not returning entries for names");
    XCTAssertNotNil([registrar registryEntryForName:@"alias"], "RegistryEntry is not returning entries for aliases");
    XCTAssertNil([registrar registryEntryForName:@"blah"], "RegistryEntry is returning entries for unregistered names or aliases");

}


- (void)validateActionIsRegistered:(UAAction *)action
                              name:(NSString *)name
                             alias:(NSString *)alias
                         predicate:(UAActionPredicate)predicate {

    UAActionRegistryEntry *entry = [[UAActionRegistrar shared] registryEntryForName:name];

    XCTAssertNotNil(entry, @"Action is not registered");
    XCTAssertEqualObjects(entry.action, action, @"Registered entry's action is incorrect");
    XCTAssertEqualObjects(entry.predicate, predicate, @"Registered entry's predicate is incorrect");
    XCTAssertEqualObjects(entry.predicate, predicate, @"Registered entry's predicate is incorrect");
    XCTAssertEqualObjects(entry.name, name, @"Registered entry's name is incorrect");
    XCTAssertEqualObjects(entry.alias, alias, @"Registered entry's alias is incorrect");
}

@end
