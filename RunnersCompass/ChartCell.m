//
//  ChartCell.m
//  RunnersCompass
//
//  Created by Geoff MacDonald on 2013-02-16.
//  Copyright (c) 2013 Geoff MacDonald. All rights reserved.
//

#import "ChartCell.h"
#import "AnimationUtil.h"

@implementation ChartCell

@synthesize folderImage;
@synthesize headerLabel;
@synthesize expandedView;
@synthesize statView;
@synthesize headerView;
@synthesize currentLabel,currentValueLabel,previousLabel,previousValueLabel;
@synthesize delegate;
@synthesize selectedValueLabel,allTimeValueLabel;
@synthesize associated;
@synthesize expanded,loadedGraph;
@synthesize weekly;
@synthesize scrollView;
@synthesize selectedLabel,allTimeLabel;
@synthesize weeklyValues,monthlyValues;
@synthesize raceCell;
@synthesize metric,showSpeed;

#pragma mark - Lifecycle

-(void)setup
{
    loadedGraph = false;
    [self loadChart];
    
    [self setExpand:false withAnimation:false];
    
    //set title to match the metric
    if(!raceCell)
        [headerLabel setText:[RunEvent stringForMetric:associated showSpeed:showSpeed]];
    else
        [headerLabel setText:[RunEvent stringForRace:associated]];
    
    [scrollView setDelegate:self];
    
    //localized buttons in IB
    [selectedLabel setText:NSLocalizedString(@"PerformanceSelectedLabel", @"label for selected performance")];
    [allTimeLabel setText:NSLocalizedString(@"PerformanceAllTimeLabel", @"label for all time performance")];
}

-(void)setTimePeriod:(BOOL) toWeekly
{
    weekly = toWeekly;
    
    NSTimeInterval highest= 0;
    NSTimeInterval lowest= [NSDate timeIntervalSinceReferenceDate];
    NSTimeInterval allTime = 0;
    NSInteger recordCount = 0;
    NSNumber* current;
    NSNumber* previous;
    
    //set weekly labels, with localization
    if(toWeekly)
    {
        [previousLabel setText:NSLocalizedString(@"PerformancePreviousWeek", @"previous week in performance")];
        [currentLabel setText:NSLocalizedString(@"PerformanceCurrentWeek", @"current week in performance")];
        
        //set all time high and selected
        for(NSNumber * num in weeklyValues)
        {
            //mostly for pace
            if([num floatValue] > 0)
            {
                allTime += [num floatValue];
                recordCount++;
            }
            
            if([num floatValue] > highest)
                highest = [num floatValue];
            
            if([num floatValue] < lowest)
                lowest = [num floatValue];
        }
        
        //set value for previous,current
        if([weeklyValues count] > 0)
            current = [weeklyValues objectAtIndex:0];
        else
            previous = [NSNumber numberWithInt:0];
        if([weeklyValues count] > 1)
            previous = [weeklyValues objectAtIndex:1];
        else
            previous = [NSNumber numberWithInt:0];
    }
    else
    {
        [previousLabel setText:NSLocalizedString(@"PerformancePreviousMonth", @"previous month in performance")];
        [currentLabel setText:NSLocalizedString(@"PerformanceCurrentMonth", @"current month in performance")];
        
        //set all time high and selected
        for(NSNumber * num in monthlyValues)
        {
            //mostly for pace
            if([num floatValue] > 0)
            {
                allTime += [num floatValue];
                recordCount++;
            }
            
            if([num floatValue] > highest)
                highest = [num floatValue];
            if([num floatValue] < lowest)
                lowest = [num floatValue];
        }
        
        //set value for previous,current
        if([monthlyValues count] > 0)
            current = [monthlyValues objectAtIndex:0];
        else
            previous = [NSNumber numberWithInt:0];
        if([monthlyValues count] > 1)
            previous = [monthlyValues objectAtIndex:1];
        else
            previous = [NSNumber numberWithInt:0];
    }
    
    //always average paces for races
    if(raceCell)
    {
        if(recordCount > 0)
            allTime = allTime / recordCount;
        
        [currentValueLabel setText:[RunEvent getTimeString:[current integerValue]]];
        [previousValueLabel setText:[RunEvent getTimeString:[previous integerValue]]];
        [allTimeValueLabel setText:[RunEvent getTimeString:allTime]];
    }
    else{
        //calc alltime avg pace if associated is pace
        if(associated == MetricTypePace && recordCount > 0)
            allTime = allTime / recordCount;
        
        switch(associated)
        {
            case MetricTypeDistance:
                [currentValueLabel setText:[NSString stringWithFormat:@"%.1f", [RunEvent getDisplayDistance:[current floatValue] withMetric:metric]]];
                [previousValueLabel setText:[NSString stringWithFormat:@"%.1f", [RunEvent getDisplayDistance:[previous floatValue] withMetric:metric]]];
                [allTimeValueLabel setText:[NSString stringWithFormat:@"%.1f", [RunEvent getDisplayDistance:allTime withMetric:metric]]];
                break;
            case MetricTypePace:
                [currentValueLabel setText:[RunEvent getPaceString:[current floatValue] withMetric:metric showSpeed:showSpeed]];
                [previousValueLabel setText:[RunEvent getPaceString:[previous floatValue] withMetric:metric showSpeed:showSpeed]];
                [allTimeValueLabel setText:[RunEvent getPaceString:allTime withMetric:metric showSpeed:showSpeed]];
                break;
            case MetricTypeTime:
                [currentValueLabel setText:[RunEvent getTimeString:[current integerValue]]];
                [previousValueLabel setText:[RunEvent getTimeString:[previous integerValue]]];
                [allTimeValueLabel setText:[RunEvent getTimeString:allTime]];
                break;
            case MetricTypeCalories:
                [currentValueLabel setText:[NSString stringWithFormat:@"%.0f", [current floatValue]]];
                [previousValueLabel setText:[NSString stringWithFormat:@"%.0f", [previous floatValue]]];
                [allTimeValueLabel setText:[NSString stringWithFormat:@"%.0f", allTime]];
                break;
                
            default:
                break;
        }
    }
    
    //deter chart y range
    minY = 0;
    maxY = highest * 1.05;
    
    //reload data if already loaded
    if(loadedGraph)
    {
        loadedGraph = false;
        
        [self loadChart];
    }
    
}

- (IBAction)expandTapped:(id)sender {
}

- (IBAction)headerTapped:(id)sender {
    
    [self setExpand:!expanded withAnimation:true];
}

-(void) setAssociated:(RunMetric) metricToAssociate
{
    associated = metricToAssociate;
    
    
    [self setup];
}

-(void)setExpand:(BOOL)open withAnimation:(BOOL) animate
{
    
    expanded = open;
    
    NSTimeInterval time = animate ? folderRotationAnimationTime : 0.01f;
    
    if(expanded){
        
        
        [AnimationUtil rotateImage:folderImage duration:time curve:UIViewAnimationCurveEaseIn degrees:90];
        
        if(animate)
        {
            [AnimationUtil cellLayerAnimate:scrollView toOpen:true];
            [AnimationUtil cellLayerAnimate:statView toOpen:true];
        }
        
        
        if(!loadedGraph)
        {
            [self loadChart];
        }
        
    }else{
        
        if(animate)
        {
            [AnimationUtil cellLayerAnimate:scrollView toOpen:false];
            [AnimationUtil cellLayerAnimate:statView toOpen:false];
            
        }
        
        [AnimationUtil rotateImage:folderImage duration:time curve:UIViewAnimationCurveEaseIn degrees:0];
    }
    
    if(!animate)
    {
        [scrollView setHidden:!open];
        [statView setHidden:!open];
    }
    
    
    [delegate cellDidChangeHeight:self];
    
    
}



-(CGFloat)getHeightRequired
{
    
    if(!expanded)
    {
        return headerView.frame.size.height;
    }else{
        return headerView.frame.size.height + scrollView.frame.size.height;
    }
    
}

#pragma mark - BarChart

-(void)loadChart
{
    NSInteger numBars = (weekly ? [weeklyValues count] : [monthlyValues count]);
    
    //set size of view of graph to be equal to that of the split load
    CGRect graphRect = expandedView.frame;
    graphRect.size = CGSizeMake(performanceSplitObjects * performanceBarWidth, scrollView.frame.size.height);
    //set origin so that view is drawn for split filling up the last possible view
    graphRect.origin = CGPointMake((numBars * performanceBarWidth) - graphRect.size.width, 0.0);
    [expandedView setFrame:graphRect];
    
    [self barPlot:nil barWasSelectedAtRecordIndex:0];
    
    //draw bar graph with new data from run
    lastCacheMinute = numBars- performanceSplitObjects;
    CPTPlotRange * firstRangeToShow = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(lastCacheMinute) length:CPTDecimalFromInt(performanceSplitObjects)];
    [self setupGraphForView:expandedView withRange:firstRangeToShow];
    
    //set scroll to be at the end
    [scrollView setContentSize:CGSizeMake(numBars * performanceBarWidth, scrollView.frame.size.height)];
    [scrollView setContentOffset:CGPointMake((numBars  * performanceBarWidth) - scrollView.frame.size.width, 0)];
    
    loadedGraph = true;
}

-(void)setupGraphForView:(CPTGraphHostingView *)hostingView withRange:(CPTPlotRange *)range
{
    
    
    // Create barChart from theme
    barChart = [[CPTXYGraph alloc] initWithFrame:CGRectZero];
    CPTTheme *theme = [CPTTheme themeNamed:kCPTPlainWhiteTheme];
    [barChart applyTheme:theme];
    expandedView.hostedGraph = barChart;
    
    // Border
    barChart.plotAreaFrame.borderLineStyle = nil;
    barChart.plotAreaFrame.cornerRadius    = 0.0f;
    
    // Paddings for view
    barChart.paddingLeft   = 0.0f;
    barChart.paddingRight  = 0.0f;
    barChart.paddingTop    = 0.0f;
    barChart.paddingBottom = 0.0f;
    
    //plot area
    barChart.plotAreaFrame.paddingLeft   = 0.0f;
    barChart.plotAreaFrame.paddingTop    = 25.0;//for selected labels
    barChart.plotAreaFrame.paddingRight  = 0.0f;
    barChart.plotAreaFrame.paddingBottom = 20.0f;
    barChart.plotAreaFrame.masksToBorder = NO;
    
    //look modification
    barChart.plotAreaFrame.fill = [CPTFill fillWithColor:[CPTColor clearColor]];
    barChart.fill = [CPTFill fillWithColor:[CPTColor clearColor]];
    
    
    // Add plot space for horizontal bar charts
    plotSpace = (CPTXYPlotSpace *)barChart.defaultPlotSpace;
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(minY) length:CPTDecimalFromFloat(maxY)];
    plotSpace.xRange = range;
    
    //x-axis
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)barChart.axisSet;
    CPTXYAxis *x          = axisSet.xAxis;
    x.labelingPolicy = CPTAxisLabelingPolicyNone;
    x.majorIntervalLength = CPTDecimalFromString(@"1");
    x.orthogonalCoordinateDecimal = CPTDecimalFromString(@"0");
    
    //labels for x-axis
    CPTMutableTextStyle * dateLabelTextStyle = [CPTMutableTextStyle textStyle];
    dateLabelTextStyle.color = [CPTColor lightGrayColor];
    dateLabelTextStyle.fontSize = 12;
    x.labelTextStyle = dateLabelTextStyle;
    //analysis results gauranteed to be as of today
    NSDate * today = [NSDate date];
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [calendar components:NSWeekCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit fromDate:today];
    if(weekly)
    {
        NSInteger startWeek = components.week;
        NSMutableArray *labels = [[NSMutableArray alloc] initWithCapacity:[weeklyValues count]/12];
        int idx = startWeek;
        int dateIndex = 0;
        //for each week ,if multiple of 13 , add label representing nearest month
        for (NSNumber * valueToLabel  in weeklyValues)
        {
            if(idx ==0)
                idx = 52;
            
            if(idx % 13 == 0)
            {
                NSString * tempLabel;
                
                switch(idx/13)
                {
                    case 1:
                        tempLabel = NSLocalizedString(@"AprilMonth", "month string");// @"April";
                        break;
                    case 2:
                        tempLabel = NSLocalizedString(@"JulyMonth", "month string");// @"July";
                        break;
                    case 3:
                        tempLabel = NSLocalizedString(@"OctoberMonth", "month string");// @"October";
                        break;
                    case 4:
                        tempLabel = NSLocalizedString(@"JanuaryMonth", "month string");// @"January";
                        break;
                        
                }
                
                if(tempLabel)
                {
                    CPTAxisLabel *label = [[CPTAxisLabel alloc] initWithText:tempLabel textStyle:dateLabelTextStyle];
                    //indexes are relative to start week, ie 7,6,5,4,3,2,1
                    label.tickLocation = CPTDecimalFromInt([weeklyValues count] - dateIndex);
                    label.offset = 5.0f;
                    [labels addObject:label];
                }
            }
            //decrement week 
            idx--;
            //increase index
            dateIndex++;
        }
        x.axisLabels = [NSSet setWithArray:labels];
    }
    else
    {
        //set years instead for months
        
        NSInteger startMonth = components.month;
        NSInteger startYear = components.year;
        NSMutableArray *labels = [[NSMutableArray alloc] initWithCapacity:[monthlyValues count]/12];
        int idx = startMonth;
        int dateIndex = 0;
        for (NSNumber * valueToLabel  in monthlyValues)
        {
            if(idx ==0)
                idx = 12;
            
            if(idx / 12 == 1)
            {
                NSString * tempLabel;
                
                tempLabel = [NSString stringWithFormat:@"%d", startYear];
                
                if(tempLabel)
                {
                    CPTAxisLabel *label = [[CPTAxisLabel alloc] initWithText:tempLabel textStyle:dateLabelTextStyle];
                    label.tickLocation = CPTDecimalFromInt([monthlyValues count] - dateIndex);
                    label.offset = 5.0f;
                    [labels addObject:label];
                }
                
                startYear -= 1;
            }
            idx--;
            dateIndex++;
        }
        x.axisLabels = [NSSet setWithArray:labels];
    }

    
    //y-axis
    CPTXYAxis *y = axisSet.yAxis;
    y.labelingPolicy = CPTAxisLabelingPolicyNone;
    
    //axis line style
    CPTMutableLineStyle *majorLineStyle = [CPTMutableLineStyle lineStyle];
    majorLineStyle.lineCap   = kCGLineCapRound;
    majorLineStyle.lineColor = [CPTColor colorWithGenericGray:CPTFloat(0.15)];
    majorLineStyle.lineWidth = CPTFloat(1.0);
    x.axisLineStyle                  = majorLineStyle;
    
    
    // add bar plot to view, all bar customization done here
    CPTColor * barColour = [CPTColor colorWithComponentRed:0.8f green:0.1f blue:0.15f alpha:1.0f];
    barPlot = [CPTBarPlot tubularBarPlotWithColor:barColour horizontalBars:NO];
    barPlot.baseValue  = CPTDecimalFromString(@"0");
    barPlot.dataSource = self;
    barPlot.identifier = kPlot;
    barPlot.barWidth                      = CPTDecimalFromDouble(0.7);
    barPlot.barWidthsAreInViewCoordinates = NO;
    barPlot.barCornerRadius               = CPTFloat(5.0);
    barPlot.barBaseCornerRadius             = CPTFloat(5.0);
    CPTGradient *fillGradient = [CPTGradient gradientWithBeginningColor:[CPTColor darkGrayColor] endingColor:[CPTColor darkGrayColor]];
    fillGradient.angle = 0.0f;
    barPlot.fill       = [CPTFill fillWithGradient:fillGradient];
    barPlot.delegate = self;
    
    
    [barChart addPlot:barPlot toPlotSpace:plotSpace];
    
    
    
    //selected Plot
    selectedPlot = [[CPTBarPlot alloc] init];
    selectedPlot.fill = [CPTFill fillWithColor:[CPTColor colorWithComponentRed:0.8f green:0.1f blue:0.15f alpha:1.0f]];
    CPTMutableLineStyle *selectedBorderLineStyle = [CPTMutableLineStyle lineStyle];
	selectedBorderLineStyle.lineWidth = CPTFloat(0.5);
    selectedPlot.lineStyle = selectedBorderLineStyle;
    selectedPlot.barWidth = CPTDecimalFromString(@"0.7");
    selectedPlot.barCornerRadius               = CPTFloat(5.0);
    selectedPlot.barBaseCornerRadius             = CPTFloat(5.0);
    selectedPlot.baseValue  = CPTDecimalFromString(@"0");
    
    selectedPlot.dataSource = self;
    selectedPlot.identifier = kSelectedPlot;
    selectedPlot.delegate = self;
    
    [barChart addPlot:selectedPlot toPlotSpace:plotSpace];
    
    
    loadedGraph = true;
    
    
}

#pragma mark -
#pragma mark Plot Data Source Methods


-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    //return number of checkpoints for run to determine # of bars
    if(weekly)
        return [weeklyValues count];
    else
        return [monthlyValues count];
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    NSNumber * numberValue;
    
    if ( [plot isKindOfClass:[CPTBarPlot class]] ) {
        switch ( fieldEnum ) {
            case CPTBarPlotFieldBarLocation:
                
                //x location of index is opposite side of chart such that weeklyValue[0] is latest run
                
                if(weekly)
                    numberValue = [NSNumber numberWithInt:([weeklyValues count] - index - 0.5)];
                else
                    numberValue = [NSNumber numberWithInt:([monthlyValues count] - index - 0.5)];
                break;
                
            case CPTBarPlotFieldBarTip:
                //y location of bar
                    if([plot.identifier isEqual: kPlot] ||  ([plot.identifier isEqual: kSelectedPlot] && index == selectedBarIndex))
                    {
                        if(weekly && [weeklyValues count] > index)
                            numberValue = [weeklyValues objectAtIndex:index];
                        else if([monthlyValues count] > index)
                            numberValue = [monthlyValues objectAtIndex:index];
                        else
                            numberValue = [NSNumber numberWithInt:0];
                    }
                break;
        }
    }
    
    return numberValue;
}

#pragma mark - Bar Plot deleget methods

-(void)barPlot:(CPTBarPlot *)plot barWasSelectedAtRecordIndex:(NSUInteger)idx
{
    //set the select pace
    selectedBarIndex = idx;
    
    
    [selectedPlot reloadData];
    //[barPlot reloadData];//need to correct cleared fill
    
    
    //change selected values
    NSNumber* valueToDisplay = [NSNumber numberWithInt:0];
    
    if(weekly && [weeklyValues count] > idx)
        valueToDisplay = [weeklyValues objectAtIndex:idx];
    else if([monthlyValues count] > idx)
        valueToDisplay = [monthlyValues objectAtIndex:idx];
    
    if(raceCell)
    {
        [selectedValueLabel setText:[RunEvent getTimeString:[valueToDisplay integerValue]]];
    }
    else{
        switch(associated)
        {
            case MetricTypeDistance:
                [selectedValueLabel setText:[NSString stringWithFormat:@"%.1f",[RunEvent getDisplayDistance:[valueToDisplay floatValue] withMetric:metric]]];
                break;
            case MetricTypePace:
                [selectedValueLabel setText:[RunEvent getPaceString:[valueToDisplay integerValue] withMetric:metric showSpeed:showSpeed]];
                break;
            case MetricTypeTime:
                [selectedValueLabel setText:[RunEvent getTimeString:[valueToDisplay integerValue]]];
                break;
            case MetricTypeCalories:
                [selectedValueLabel setText:[NSString stringWithFormat:@"%.0f",[valueToDisplay floatValue]]];
                break;
        }
    }
    
    
}

#pragma mark - ScrollView Delegate



-(CGFloat)convertToX:(NSInteger) minute
{
    CGFloat x =  performanceBarWidth * minute;
    
    return x;
    
}


-(NSInteger)convertToCheckpointMinute:(CGFloat)x
{
    
    NSInteger min =  x / performanceBarWidth;
    
    return min;
}

- (void)scrollViewDidScroll:(UIScrollView *)tempScrollView
{
    
    
    CGFloat curViewOffset = tempScrollView.contentOffset.x;
    NSInteger curViewMinute = [self convertToCheckpointMinute:curViewOffset];
    
    NSDecimalNumber *startLocDecimal = [NSDecimalNumber decimalNumberWithDecimal:plotSpace.xRange.location];
    NSInteger startLocationMinute = [startLocDecimal integerValue];
    CGFloat startLocation = [self convertToX:startLocationMinute];
    NSDecimalNumber *endLengthDecimal = [NSDecimalNumber decimalNumberWithDecimal:plotSpace.xRange.length];
    NSInteger endLocationMinute = [startLocDecimal integerValue] + [endLengthDecimal integerValue];
    CGFloat endLocation = [self convertToX:endLocationMinute];
    NSInteger numBars = (weekly ? [weeklyValues count] : [monthlyValues count]);
    
    
    NSLog(@"Scroll @ %.f , %d min with plot start = %f , %d min, end = %f , %d min", curViewOffset, curViewMinute, startLocation, startLocationMinute, endLocation, endLocationMinute);
    
    
    if(curViewMinute <= lastCacheMinute  && !(curViewMinute <= 0))
    {
        
        
        //reload to the left
        lastCacheMinute -= performanceSplitObjects - performanceLoadObjectsOffset;
        
        CPTPlotRange * newRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(lastCacheMinute) length:CPTDecimalFromFloat(performanceSplitObjects)];
        
        plotSpace.xRange = newRange;
        
        //move the view with the scroll view
        CGRect newGraphViewRect = [expandedView frame];
        newGraphViewRect.origin.x -= [self convertToX:performanceSplitObjects - performanceLoadObjectsOffset];
        [expandedView setFrame:newGraphViewRect];
    }
    else if(curViewMinute > lastCacheMinute + performanceSplitObjects - performanceLoadObjectsOffset &&
            !(curViewMinute + performanceLoadObjectsOffset >= numBars))
    {
        //reload to right
        lastCacheMinute += performanceSplitObjects - performanceLoadObjectsOffset;
        CPTPlotRange * newRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(lastCacheMinute) length:CPTDecimalFromFloat(performanceSplitObjects)];
        
        plotSpace.xRange = newRange;
        
        //move the view with the scroll view
        CGRect newGraphViewRect = [expandedView frame];
        newGraphViewRect.origin.x += [self convertToX:performanceSplitObjects - performanceLoadObjectsOffset];
        [expandedView setFrame:newGraphViewRect];
    }
    
    
    
}


@end
