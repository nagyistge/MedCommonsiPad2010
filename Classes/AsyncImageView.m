//
//  AsyncImageView.m
//  Postcard
//
//  Created by markj on 2/18/09.
//  Copyright 2009 Mark Johnson. You have permission to copy parts of this code into your own projects for any use.
//  www.markj.net
//

#import "AsyncImageView.h"
#import "MedCommons.h"

@implementation AsyncImageView
- (void)dealloc {
	[connection cancel]; //in case the URL is still downloading
	[connection release];
	[data release]; 
    [super dealloc];
}
-(AsyncImageView *) initWithFrame:(CGRect)frame andImageCache:(NSMutableDictionary *) mdict
{
	self = [super initWithFrame:(CGRect)frame];
	imageCache = mdict;	
	return self;
}
- (void)loadImageFromURL:(NSURL*)url {
	if (connection!=nil) { [connection release]; } //in case we are downloading a 2nd image
	// check if we can find this in the cache
	ThisURL = [url  absoluteString];
	data = (NSMutableData *)[imageCache objectForKey: ThisURL];
	if (data)
	{
		CACHE_LOG (@"found in cache: %@",[url absoluteString]);
		UIImageView* imageView = [[[UIImageView alloc] initWithImage:[UIImage imageWithData:data]]  retain ];//]autorelease];
		if (imageView)
		{
			//make sizing choices based on your needs, experiment with these. maybe not all the calls below are needed.
			imageView.contentMode = UIViewContentModeScaleAspectFit;
			//imageView.autoresizingMask = ( UIViewAutoresizingFlexibleWidth || UIViewAutoresizingFlexibleHeight );
			[imageView removeFromSuperview]; // get rid of previous crap, neither the height or width are flexible
			[self addSubview:imageView];
			imageView.frame = self.bounds;
			[imageView setNeedsLayout];
			[self setNeedsLayout];
			//[imageView retain]; // try this
		}
	}
	else
	{
		if (data!=nil) { [data release]; }
		CACHE_LOG (@"not found in cache: %@",[url absoluteString]);
		//not in cache, start an asynch request
		NSURLRequest* request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
		connection = [[NSURLConnection alloc] initWithRequest:request delegate:self]; //notice how delegate set to self object
		//TODO error handling, what if connection is nil?
	}
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error

{
	
	
	CACHE_LOG (@"connection failed for: %@ due to error %@",ThisURL,[error localizedDescription]);
	
	
}
//the URL connection calls this repeatedly as data arrives
- (void)connection:(NSURLConnection *)theConnection didReceiveData:(NSData *)incrementalData {
	if (data==nil) { data = [[NSMutableData alloc] initWithCapacity:2048]; } 
	[data appendData:incrementalData];
}
//the URL connection calls this once all the data has downloaded
- (void)connectionDidFinishLoading:(NSURLConnection*)theConnection {
	//so self data now has the complete image 
	[connection release];
	connection=nil;
	if ([[self subviews] count]>0) {
		//then this must be another image, the old one is still in subviews
		[[[self subviews] objectAtIndex:0] removeFromSuperview]; //so remove it (releases it also)
	}
	
	//make an image view for the image
	UIImageView* imageView = [[[UIImageView alloc] initWithImage:[UIImage imageWithData:data]]  autorelease];
	//make sizing choices based on your needs, experiment with these. maybe not all the calls below are needed.
	imageView.contentMode = UIViewContentModeScaleAspectFit;
	imageView.autoresizingMask = ( UIViewAutoresizingFlexibleWidth || UIViewAutoresizingFlexibleHeight );
	[self addSubview:imageView];
	imageView.frame = self.bounds;
	[imageView setNeedsLayout];
	[self setNeedsLayout];
	/* put this imageView in the cache */
	
	CACHE_LOG (@"storing data now for: %@",ThisURL);
	[imageCache setObject:data forKey:ThisURL]; // shovel data in instead
	[data release]; //don't need this any more, its in the UIImageView now
	data=nil;
}

//just in case you want to get the image directly, here it is in subviews
//- (UIImage*) image {
//	UIImageView* iv = [[self subviews] objectAtIndex:0];
//	return [iv image];
//}

@end