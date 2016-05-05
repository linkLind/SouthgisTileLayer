//
//  SouthgisTdt_TileLayer.m
//  TianDituFramework
//
//  Created by 吴小星 on 16/5/5.
//  Copyright © 2016年 crash. All rights reserved.
//

#import "SouthgisTdt_TileLayer.h"
#import "SouthgisTianDiTuWMTSLayerInfoDelegate.h"

@interface SouthgisTdt_TileLayer() {

    WMTSLayerTypes _layerType;
}

@end

@implementation SouthgisTdt_TileLayer


/**
 *  @author crash         crash_wu@163.com   , 16-05-03 08:05:04
 *
 *  @brief  初始化天地图图层
 *
 *  @param wmtsLayerType 天地图图层类型
 *  @param outError      图层加载错误信息
 *
 *  @return 天地图图层
 */
- (instancetype)initWithLayerType:(WMTSLayerTypes) wmtsLayerType  error:(NSError**) outError{
    
    _layerType = wmtsLayerType;
    
    if (self = [super initWithCachePath:[self retFilePath]]) {
        
        /*get the currect layer info
         */
        _layerInfo = [[SouthgisTianDiTuWMTSLayerInfoDelegate alloc]getLayerInfo:wmtsLayerType];
        
        
        AGSSpatialReference* sr = [AGSSpatialReference spatialReferenceWithWKID:_layerInfo.srid];
        _fullEnvelope = [[AGSEnvelope alloc] initWithXmin:_layerInfo.xMin
                                                     ymin:_layerInfo.yMin
                                                     xmax:_layerInfo.xMax
                                                     ymax:_layerInfo.yMax
                                         spatialReference:sr];
        
        _tileInfo = [[AGSTileInfo alloc]
                     initWithDpi:_layerInfo.dpi
                     format :@"PNG"
                     lods:_layerInfo.lods
                     origin:_layerInfo.origin
                     spatialReference :self.spatialReference
                     tileSize:CGSizeMake(_layerInfo.tileWidth,_layerInfo.tileHeight)
                     ];
        [_tileInfo computeTileBounds:self.fullEnvelope];
        
        [super layerDidLoad];
        
    }
    
    return self;
}


- (void)requestTileForKey:(AGSTileKey *)key{
    
    
    __weak typeof(self) weakSelf = self;
    
    [self loadTileDataFromCacheWithTileKey:key loadCompleteBlock:^(NSData *data) {
        
        if (data) {
            
            [weakSelf setTileData:data forKey:key];
            
        }
        else{
            Southgis_WMTSLayerOperation *operation = [[Southgis_WMTSLayerOperation alloc]initWithTileKey:key TiledLayerInfo:_layerInfo target:weakSelf action:@selector(didFinishOperation:)];
            
            [_requestQueue addOperation:operation];
        }
    }];
    
    
    
}

- (void)cancelRequestForKey:(AGSTileKey *)key{
    //Find the Southigs_TiledServiceLayerOperation object for this key and cancel it
    for(NSOperation* op in [AGSRequestOperation sharedOperationQueue].operations){
        if( [op isKindOfClass:[Southgis_WMTSLayerOperation class]]){
            Southgis_WMTSLayerOperation* offOp = (Southgis_WMTSLayerOperation*)op;
            if([offOp.tileKey isEqualToTileKey:key]){
                [offOp cancel];
            }
        }
    }
}

- (void) didFinishOperation:(Southgis_WMTSLayerOperation*)op{
    
    [super setTileData:op.imageData forKey:op.tileKey];
    
    
}



/**
 * @author Jeremy, 16-03-10 11:03:44
 *
 * 返回缓存路径
 *
 * @param tileKey
 *
 * @return 路径
 */
- (NSString *)retFilePath{
    
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,  NSUserDomainMask,YES);
    
    NSString *docPath = [documentPaths objectAtIndex:0];
    
    //通过图层类型创建文件夹保存切片
    NSString *createPath = [NSString stringWithFormat:@"%@/tdt/%d", docPath,_layerType];
    
    
    return createPath;
}




@end
