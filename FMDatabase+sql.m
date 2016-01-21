//
//  FMDatabase+sql.m
//  fmdb_test
//
//  Created by XITEHIP on 16/1/9.
//  Copyright © 2016年 safd. All rights reserved.
//

#import "FMDatabase+sql.h"
#import "BaseDTO.h"

#define WHERE_KEY      @"whereKey"
#define WHERE_VALUE    @"whereValue"
#define FIELDS         @"fields"
#define TABLE_NAME     @"tableName"
#define LIMIT          @"limit"
#define ORDER_BY       @"orderBy"
#define DTO_CLASS      @"dtoClass"

#define OBJ_SET(key, value) [[[self class] _td] setObject:value forKey:key]
#define OBJ_GET(key) [[[self class] _td] objectForKey:key]

@implementation FMDatabase (sql)

NSMutableDictionary *_td;

+ (NSMutableDictionary *)_td
{
    if (!_td) {
        _td = [[NSMutableDictionary alloc] init];
    }
    return _td;
}

- (FieldsBlock)field
{
    return ^id(NSArray *params) {
        NSAssert([params isKindOfClass:[NSArray class]], @"params must be array!!");
        if (params.count == 0) {
            OBJ_SET(FIELDS, @"*");
        } else {
            NSMutableString *fields = [[NSMutableString alloc] init];
            [params enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {

                NSAssert([obj isKindOfClass:[NSString class]], @"field must be string!!");
                if (params.count - 1 == idx) {
                    [fields appendFormat:@"%@", obj];
                } else {
                    [fields appendFormat:@"%@, ", obj];
                }
            }];
            OBJ_SET(FIELDS, fields);
        }
        return self;
    };
}

- (TableNameBlock)table
{
    return ^id(NSString *table) {
        OBJ_SET(TABLE_NAME, table);
        return self;
    };
}

- (WhereBlock)where
{
    return ^id(NSDictionary *params, NSString *andor) {
        NSAssert([params isKindOfClass:[NSDictionary class]] && params.count > 0, @"param is not dictionary or is empty!!");
        NSAssert([andor isKindOfClass:[NSString class]], @"the second param must be string");
        andor = [andor uppercaseString];
        if (andor.length == 0 || (![andor isEqualToString:@"AND"] && ![andor isEqualToString:@"OR"])) {
            andor = @"AND";
        }
        __block NSMutableString *whereKeyStr = [[NSMutableString alloc] init];
        __block NSMutableArray *whereValueArray = [[NSMutableArray alloc] init];
        __block int i = 0;
        [params enumerateKeysAndObjectsUsingBlock:^(NSString *key, id  _Nonnull obj, BOOL * _Nonnull stop) {
             NSString *split = @"";
            if (OBJ_GET(WHERE_KEY)) {
                split = andor;
            } else {
                split = i == 0 ? @"" : andor;
            }
            if ([split isEqualToString:@""]) {
                [whereKeyStr appendFormat:@" %@ = ?", key];
            } else {
                [whereKeyStr appendFormat:@" %@ %@ = ?", split, key];
            }
            [whereValueArray addObject:obj];
            i++;
        }];
        
        if (OBJ_GET(WHERE_KEY)) {
            [OBJ_GET(WHERE_KEY) appendFormat:@"%@", whereKeyStr];
            [OBJ_GET(WHERE_VALUE) addObjectsFromArray:whereValueArray];
        } else {
            OBJ_SET(WHERE_KEY, whereKeyStr);
            OBJ_SET(WHERE_VALUE, whereValueArray);
        }
        return self;
    };
}

#pragma mark result data - getter

- (GetBlock)get
{
    return ^id() {
        NSMutableString *fields = OBJ_GET(FIELDS);
        
        if (fields == nil) {
            fields = [[NSMutableString alloc] initWithString:@"*"];
        }
        
        NSString *tableName = OBJ_GET(TABLE_NAME);
        NSAssert(tableName, @"table name is empty!!");
        
        NSMutableString *where = OBJ_GET(WHERE_KEY);
        NSMutableString *sql = [[NSMutableString alloc] init];
        if (where == nil) {
            [sql appendFormat:@"SELECT %@ From %@", fields, tableName];
        } else {
            [sql appendFormat:@"SELECT %@ From %@ WHERE%@", fields, tableName, where];
        }
        
        NSString *orderBy = OBJ_GET(ORDER_BY);
        if (orderBy) {
            [sql appendFormat:@" ORDER BY %@", orderBy];
        }
        NSString *limit = OBJ_GET(LIMIT);
        if (limit) {
            [sql appendFormat:@" LIMIT %@", limit];
        }
        
        NSArray *argumentArray = OBJ_GET(WHERE_VALUE);
        FMResultSet *rs = [self executeQuery:sql withArgumentsInArray:argumentArray];
        NSMutableArray *data = [NSMutableArray array];
        while ([rs next]) {
            NSDictionary *rowDict = [rs resultDictionary];
            Class class = OBJ_GET(DTO_CLASS);
            if (class) {
                BaseDTO *dto = [(BaseDTO *)[class alloc] init:rowDict];
                [data addObject:dto];
            } else {
                [data addObject:rowDict];
            }
        }
        [rs close];
        _td = nil;
        return data;
    };
}

- (CountBlock)count
{
    return ^int() {
        return (int)[self.get() count];
    };
}

- (LimitBlock)limit
{
    return ^id(NSString *limitStr) {
        OBJ_SET(LIMIT, limitStr);
        return self;
    };
}

- (OrderByBlock)orderBy
{
    return ^id(NSString *field, NSString *sort) {
        
        NSAssert([field isKindOfClass:[NSString class]] && ![field isEqualToString:@""], @"field invalid!!");
        if (sort == nil || sort == NULL || [sort isEqualToString:@""]) {
            sort = @"ASC";
        }
        if (![[sort uppercaseString] isEqualToString:@"ASC"] && ![[sort uppercaseString] isEqualToString:@"DESC"]) {
            sort = @"ASC";
        }
        NSString *orderBy = [NSString stringWithFormat:@"%@ %@", [field uppercaseString], [sort uppercaseString]];
        OBJ_SET(ORDER_BY, orderBy);
        return self;
    };
}

- (GetWithClassBlock)getWithClass
{
    return ^id(Class cls) {
        OBJ_SET(DTO_CLASS, cls);
        return self.get();
    };
}

- (InsertBlock)insert
{
    return ^(NSArray *data) {
        NSAssert([data isKindOfClass:[NSArray class]] && data.count > 0, @"insert array is invalid!!");
        
        NSString *tableName = OBJ_GET(TABLE_NAME);
        NSAssert([tableName isKindOfClass:[NSString class]] && tableName.length > 0, @"insert table name is invalid!!");
        
        NSMutableString *insertSql = [[NSMutableString alloc] init];
        [insertSql appendFormat:@"INSERT INTO %@ (", OBJ_GET(TABLE_NAME)];
        
        NSMutableString *fields = [[NSMutableString alloc] init];
        NSMutableString *values = [[NSMutableString alloc] init];
        NSMutableArray *valuesData = [[NSMutableArray alloc] init];
        [data enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSAssert([obj isKindOfClass:[NSDictionary class]], @"obj must be dictionary");
            
            NSString *key = [obj allKeys][0];
            NSAssert([key isKindOfClass:[NSString class]] && key.length > 0, @"field key is invalid!!");
            
            NSObject *value = [obj allValues][0];
            NSAssert(value != nil, @"field value is invalid!!");
            
            NSString *split = idx == data.count - 1 ? @"" : @",";
            [fields appendFormat:@"%@%@ ", key, split];
            [values appendFormat:@"?%@ ", split];
            [valuesData addObject:value];
        }];
        [fields appendFormat:@") VALUES ( %@)", values];
        [insertSql appendString:fields];
        
        BOOL isOK =  [self executeUpdate:insertSql withArgumentsInArray:valuesData];
        if (!isOK) NSLog(@"%@ insert error", OBJ_GET(TABLE_NAME));
    };
}

- (UpdateBlock)update
{
    return ^(NSArray *data) {
        NSAssert([data isKindOfClass:[NSArray class]] && data.count > 0, @"update field array is invalid!!");
        
        NSString *tableName = OBJ_GET(TABLE_NAME);
        NSAssert([tableName isKindOfClass:[NSString class]] && tableName.length > 0, @"update table name is invalid!!");
        
        NSMutableString *updateSql = [[NSMutableString alloc] init];
        [updateSql appendFormat:@"UPDATE %@ SET ", OBJ_GET(TABLE_NAME)];
        
        NSMutableString *fields = [[NSMutableString alloc] init];
        NSMutableArray *valuesData = [[NSMutableArray alloc] init];
        [data enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSAssert([obj isKindOfClass:[NSDictionary class]], @"obj must be dictionary");
            
            NSString *key = [obj allKeys][0];
            NSAssert([key isKindOfClass:[NSString class]] && key.length > 0, @"field key is invalid!!");
            
            NSObject *value = [obj allValues][0];
            NSAssert(value != nil, @"field value is invalid!!");
            
            NSString *split = idx == data.count - 1 ? @"" : @",";
            [fields appendFormat:@"%@ = ?%@ ", key, split];
            [valuesData addObject:value];
        }];
        
        [updateSql appendString:fields];
        NSMutableString *where = OBJ_GET(WHERE_KEY);
       
        if (where != nil) {
            [updateSql appendFormat:@" WHERE %@", where];
             NSMutableArray *whereValue = OBJ_GET(WHERE_VALUE);
            [valuesData addObjectsFromArray:whereValue];
        }
        BOOL isOK =  [self executeUpdate:updateSql withArgumentsInArray:valuesData];
        if (!isOK) NSLog(@"%@ update error", OBJ_GET(TABLE_NAME));
    };
}

- (DeleteBlock)del
{
    return ^() {
        NSMutableString *delString = [[NSMutableString alloc] init];
        [delString appendFormat:@"DELETE FROM %@ ", OBJ_GET(TABLE_NAME)];
        
        NSMutableString *where = OBJ_GET(WHERE_KEY);
        if (where != nil) {
            [delString appendFormat:@"WHERE %@", where];
        }
        
        BOOL isOK = [self executeUpdate:delString withArgumentsInArray:OBJ_GET(WHERE_VALUE)];
        if (!isOK) NSLog(@"%@  delete error", OBJ_GET(TABLE_NAME));
    };
}

- (CreateTableBlock)createTable
{
    return ^(NSString *tableName, NSArray *data) {
        NSAssert([tableName isKindOfClass:[NSString class]] && tableName.length > 0, @"table name is invalid!!");
        NSMutableString *arguments = [[NSMutableString alloc] init];
        
        [arguments appendString:@"rowid INTEGER PRIMARY KEY,"];
        if ([data isKindOfClass:[NSArray class]] && data.count > 0) {
            [data enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSString *key = [obj allKeys][0];
                NSAssert([key isKindOfClass:[NSString class]] && key.length > 0, @"field key is invalid!!");
                NSString *value = [obj allValues][0];
                NSAssert([key isKindOfClass:[NSString class]] && key.length > 0, @"field value is invalid!!");
                [arguments appendFormat:@"%@ %@,", key, value];
            }];
        }
        [arguments appendString:@"info TEXT,reverse1 TEXT,reverse2 TEXT,reverse3 TEXT"];
        NSString *sqlstr = [NSString stringWithFormat:@"CREATE TABLE %@ (%@)", tableName, arguments];
        if (![self executeUpdate:sqlstr]) {
            NSLog(@"Create %@ table error!", tableName);
        }
    };
}

@end
