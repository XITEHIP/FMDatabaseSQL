//
//  FMDatabase+sql.h
//  fmdb_test
//
//  Created by XITEHIP on 16/1/9.
//  Copyright © 2016年 safd. All rights reserved.
//


/**
 
    //create table
    database.createTable(@"topic", @[@{@"topicID":@"INTETER"},@{@"create_time":@"TEXT"}]);


    //insert
    NSArray *insertData = @[
                            @{@"topicID":@3},
                            @{@"create_time":@"2016-01-13"},
                            @{@"info":@"test,test"},
                            @{@"reverse1":@""},
                            @{@"reverse2":@""},
                            @{@"reverse2":@""}];
    database.table(@"topic").insert(insertData);


    //update
    NSArray *updateData = @[@{@"create_time":@"111111"},@{@"rowid":@2222}];
    database.table(@"topic").where(@{@"rowid":@2}, @"and").update(updateData);


    //select
    [readQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSMutableArray *array = db.table(@"topic")
        .where(@{@"create_time":@3,@"info":@"11"}, @"and")
        .where(@{@"rowid":@2}, @"or")
        .where(@{@"rowid":@4}, @"")
        .field(@[@"info", @"create_time"])
        .orderBy(@"info", @"ASC")
        .limit(@"15")
        .get();
        NSLog(@"%@",array);
    }];

    //delete
    database.table(@"topic").where(@{@"rowid":@1}, @"and").del();

    //count
    [readQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        int count = db.table(@"topic").count();
        NSLog(@"%d",count);

    }];
*/

#import "FMDatabase.h"

typedef FMDatabase * (^TableNameBlock)(NSString *);
typedef FMDatabase * (^FieldsBlock)(NSArray *);
typedef FMDatabase * (^WhereBlock)(NSDictionary *, NSString *);
typedef FMDatabase * (^LimitBlock)(NSString *);
typedef FMDatabase * (^OrderByBlock)(NSString *, NSString *);

typedef NSMutableArray * (^GetBlock)();
typedef NSMutableArray * (^GetWithClassBlock)(Class cls);
typedef int (^CountBlock)();

typedef void (^InsertBlock)(NSArray *);
typedef void (^UpdateBlock)(NSArray *);
typedef void (^DeleteBlock)();

typedef void (^CreateTableBlock)(NSString *, NSArray *);


@interface FMDatabase (sql)

@property (nonatomic, copy, readonly) TableNameBlock table;
@property (nonatomic, copy, readonly) FieldsBlock field;
@property (nonatomic, copy, readonly) WhereBlock where;
@property (nonatomic, copy, readonly) OrderByBlock orderBy;
@property (nonatomic, copy, readonly) LimitBlock limit;

@property (nonatomic, copy, readonly) GetBlock get;
@property (nonatomic, copy, readonly) GetWithClassBlock getWithClass;
@property (nonatomic, copy, readonly) CountBlock count;

@property (nonatomic, copy, readonly) InsertBlock insert;
@property (nonatomic, copy, readonly) InsertBlock update;
@property (nonatomic, copy, readonly) DeleteBlock del;

@property (nonatomic, copy, readonly) CreateTableBlock createTable;

@end
