//
//  SMMapOverlays.m
//  I Bike CPH
//
//  Created by Igor Jerković on 7/29/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMMapOverlays.h"

#import "SMStationInfo.h"
#import "SMTransportation.h"
#import "SMTransportationLine.h"

@interface SMMapOverlays ()
@property(nonatomic, weak) MapView *mapView;
@property(nonatomic, readonly) NSArray *cycleSuperHighwayLocations;
@property(nonatomic, readonly) NSArray *bikeServiceStationLocations;
@property(nonatomic, readonly) NSArray *harborRingLocations;
@property(nonatomic, readonly) NSArray *greenPathsLocations;
@property(nonatomic) NSArray *cycleSuperHighwayAnnotations;
@property(nonatomic) NSArray *bikeServiceStationAnnotations;
@property(nonatomic) NSArray *harborRingAnnotations;
@property(nonatomic) NSArray *greenPathsAnnotations;
@property(nonatomic, readonly) NSArray *harborRingAnnotationColors;
@property(nonatomic, readonly) NSArray *greenPathsAnnotationColors;
@end

@implementation SMMapOverlays

@synthesize cycleSuperHighwayLocations = _cycleSuperHighwayLocations;
@synthesize bikeServiceStationLocations = _bikeServiceStationLocations;
@synthesize harborRingLocations = _harborRingLocations;
@synthesize greenPathsLocations = _greenPathsLocations;
@synthesize harborRingAnnotationColors = _harborRingAnnotationColors;
@synthesize greenPathsAnnotationColors = _greenPathsAnnotationColors;

- (SMMapOverlays *)initWithMapView:(MapView *)mapView
{
    self = [super init];
    if (self) {
        self.mapView = mapView;
    }
    return self;
}

- (void)useMapView:(MapView *)mapView
{
    self.mapView = mapView;
}

- (void)updateOverlays
{
    if (!self.mapView) {
        return;
    }

    Settings *settings = [Settings sharedInstance];

    // Show/hide Cycle Super Highways
    [self.mapView removeAnnotations:self.cycleSuperHighwayAnnotations];
    if (settings.overlays.showCycleSuperHighways) {
        [self.mapView addAnnotations:self.cycleSuperHighwayAnnotations];
    }

    // Show/hide Cycle Service Stations
    [self.mapView removeAnnotations:self.bikeServiceStationAnnotations];
    if (settings.overlays.showBikeServiceStations) {
        [self.mapView addAnnotations:self.bikeServiceStationAnnotations];
    }
    
    // Show/hide Harbor Ring
    [self.mapView removeAnnotations:self.harborRingAnnotations];
    if (settings.overlays.showHarborRing) {
        [self.mapView addAnnotations:self.harborRingAnnotations];
    }
    
    // Show/hide Green Paths
    [self.mapView removeAnnotations:self.greenPathsAnnotations];
    if (settings.overlays.showGreenPaths) {
        [self.mapView addAnnotations:self.greenPathsAnnotations];
    }

    [self.mapView.mapView setZoom:self.mapView.mapView.zoom + 0.0001];
}

- (void)updateCycleSuperHighwayAnnotations
{
    self.cycleSuperHighwayAnnotations = @[];
    if (!self.mapView) {
        return;
    }
    NSMutableArray *ma = [NSMutableArray new];
    for (NSArray *locations in self.cycleSuperHighwayLocations) {
        UIColor *color = [[Styler tintColor] colorWithAlphaComponent:0.5];
        Annotation *annotation = [self.mapView addPathWithLocations:locations lineColor:color lineWidth:4.0];
        [ma addObject:annotation];
    }
    self.cycleSuperHighwayAnnotations = ma.copy;
}

- (void)updateCycleServiceStationAnnotations
{
    self.bikeServiceStationAnnotations = @[];
    if (!self.mapView) {
        return;
    }
    NSMutableArray *ma = [NSMutableArray new];
    for (NSString *coordinates in self.bikeServiceStationLocations) {
        NSRange range = [coordinates rangeOfString:@" "];
        NSString *latitude = [coordinates substringToIndex:range.location];
        range.length = [coordinates length] - range.location;
        NSString *longitude = [coordinates substringWithRange:range];
        CLLocationCoordinate2D coord = CLLocationCoordinate2DMake([longitude floatValue], [latitude floatValue]);
        ServiceStationsAnnotation *annotation = [[ServiceStationsAnnotation alloc] initWithMapView:self.mapView coordinate:coord];
        [ma addObject:annotation];
    }
    self.bikeServiceStationAnnotations = ma.copy;
}

- (void)updateHarborRingAnnotations
{
    self.harborRingAnnotations = @[];
    if (!self.mapView) {
        return;
    }
    NSMutableArray *ma = [NSMutableArray new];
    for (NSUInteger i = 0; i < self.harborRingLocations.count; i++) {
        NSArray *locations = self.harborRingLocations[i];
        UIColor *color = self.harborRingAnnotationColors[i];
        Annotation *annotation = [self.mapView addPathWithLocations:locations lineColor:color lineWidth:4.0];
        [ma addObject:annotation];
    }
    self.harborRingAnnotations = ma.copy;
}

- (void)updateGreenPathsAnnotations
{
    self.greenPathsAnnotations = @[];
    if (!self.mapView) {
        return;
    }
    NSMutableArray *ma = [NSMutableArray new];
    for (NSUInteger i = 0; i < self.greenPathsLocations.count; i++) {
        NSArray *locations = self.greenPathsLocations[i];
        UIColor *color = self.greenPathsAnnotationColors[i];
        Annotation *annotation = [self.mapView addPathWithLocations:locations lineColor:color lineWidth:4.0];
        [ma addObject:annotation];
    }
    self.greenPathsAnnotations = ma.copy;
}

#pragma mark - Getters

- (NSArray *)cycleSuperHighwayLocations
{
    if (!_cycleSuperHighwayLocations) {
        NSDictionary *JSONDictionary = [self JSONDictionaryFromFileWithName:@"cycle_super_highways" extension:@"json"];
        NSArray *lines = JSONDictionary[@"coordinates"];
        NSMutableArray *ma = [NSMutableArray new];
        for (NSArray *line in lines) {
            NSMutableArray *locations = [NSMutableArray new];
            for (NSArray *coordinate in line) {
                float longitude = [coordinate[0] floatValue];
                float latitude = [coordinate[1] floatValue];
                CLLocation *location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
                [locations addObject:location];
            }
            [ma addObject:locations];
        }
        _cycleSuperHighwayLocations = ma.copy;
    }
    return _cycleSuperHighwayLocations;
}

- (NSArray *)bikeServiceStationLocations
{
    if (!_bikeServiceStationLocations) {
        NSDictionary *JSONDictionary = [self JSONDictionaryFromFileWithName:@"stations" extension:@"json"];
        NSArray *stations = JSONDictionary[@"stations"];
        NSMutableArray *ma = [NSMutableArray new];
        for (NSDictionary *station in stations) {
            // Only import service stations
            if (![station[@"type"] isEqualToString:@"service"]) {
                continue;
            }
            NSString *coordinates = station[@"coords"];
            [ma addObject:coordinates];
        }
        _bikeServiceStationLocations = ma.copy;
    }
    return _bikeServiceStationLocations;
}

- (NSArray *)harborRingLocations
{
    if (!_harborRingLocations) {
        NSDictionary *JSONDictionary = [self JSONDictionaryFromFileWithName:@"harbor_ring" extension:@"geojson"];
        NSArray *features = JSONDictionary[@"features"];
        NSMutableArray *ma = [NSMutableArray new];
        for (NSDictionary *feature in features) {
            NSArray *coordinates = [[feature objectForKey:@"geometry"] objectForKey:@"coordinates"];
            NSMutableArray *locations = [NSMutableArray new];
            for (NSArray *coordinate in coordinates) {
                float longitude = [coordinate[0] floatValue];
                float latitude = [coordinate[1] floatValue];
                CLLocation *location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
                [locations addObject:location];
            }
            [ma addObject:locations];
        }
        _harborRingLocations = ma.copy;
    }
    return _harborRingLocations;
}

- (NSArray *)harborRingAnnotationColors
{
    if (!_harborRingAnnotationColors) {
        NSDictionary *JSONDictionary = [self JSONDictionaryFromFileWithName:@"harbor_ring" extension:@"geojson"];
        NSArray *features = JSONDictionary[@"features"];
        NSMutableArray *ma = [NSMutableArray new];
        for (NSDictionary *feature in features) {
            NSString *colorString = [[feature objectForKey:@"properties"] objectForKey:@"color"];
            UIColor *color = [[Styler tintColor] colorWithAlphaComponent:0.5f];
            if (colorString) {
                color = [[UIColor greenColor] colorWithAlphaComponent:0.5f];
            }
            [ma addObject:color];
        }
        _harborRingAnnotationColors = ma.copy;
    }
    return _harborRingAnnotationColors;
}

- (NSArray *)greenPathsLocations
{
    if (!_greenPathsLocations) {
        NSDictionary *JSONDictionary = [self JSONDictionaryFromFileWithName:@"green_paths" extension:@"geojson"];
        NSArray *features = JSONDictionary[@"features"];
        NSMutableArray *ma = [NSMutableArray new];
        for (NSDictionary *feature in features) {
            NSArray *coordinates = [[feature objectForKey:@"geometry"] objectForKey:@"coordinates"];
            NSMutableArray *locations = [NSMutableArray new];
            for (NSArray *coordinate in coordinates) {
                float longitude = [coordinate[0] floatValue];
                float latitude = [coordinate[1] floatValue];
                CLLocation *location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
                [locations addObject:location];
            }
            [ma addObject:locations];
        }
        _greenPathsLocations = ma.copy;
    }
    return _greenPathsLocations;
}

- (NSArray *)greenPathsAnnotationColors
{
    if (!_greenPathsAnnotationColors) {
        NSDictionary *JSONDictionary = [self JSONDictionaryFromFileWithName:@"green_paths" extension:@"geojson"];
        NSArray *features = JSONDictionary[@"features"];
        NSMutableArray *ma = [NSMutableArray new];
        for (NSDictionary *feature in features) {
            NSString *colorString = [[feature objectForKey:@"properties"] objectForKey:@"color"];
            UIColor *color = [[Styler tintColor] colorWithAlphaComponent:0.5f];
            if (colorString) {
                color = [[UIColor greenColor] colorWithAlphaComponent:0.5f];
            }
            [ma addObject:color];
        }
        _greenPathsAnnotationColors = ma.copy;
    }
    return _greenPathsAnnotationColors;
}

#pragma mark - Setters

- (void)setMapView:(MapView *)mapView
{
    _mapView = mapView;
    [self updateCycleSuperHighwayAnnotations];
    [self updateCycleServiceStationAnnotations];
    [self updateHarborRingAnnotations];
    [self updateGreenPathsAnnotations];
}

#pragma mark - Helpers

- (NSDictionary *)JSONDictionaryFromFileWithName:(NSString *)name extension:(NSString *)extension
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:name ofType:extension];
    if (!filePath) {
        NSLog(@"Could not find file %@.%@",name, extension);
        return nil;
    }
    NSError *err;
    NSData *data = [NSData dataWithContentsOfFile:filePath options:0 error:&err];
    if (err) {
        NSLog(@"Could not create data object from file %@.%@: %@", name, extension, err);
        return nil;
    }
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
    if (err) {
        NSLog(@"Could not parse JSON from file %@.%@: %@", name, extension, err);
        return nil;
    }
    return dictionary;
}

@end