/*
 * Copyright 2010-present Facebook.
 *
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *    http://www.apache.org/licenses/LICENSE-2.0
 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 *
 * Aug 19. 2013 - Modified to process the query as a single Graph API Explorer generated query
 *				  AND let you choose permisssions too. Read the README.TXT!!
 *                By Eric Hayes, Indie / frelance developer, Brewmium.com
 */

#import <FacebookSDK/FacebookSDK.h>
#import "GraphApiAppDelegate.h"
#import "GraphApiViewController.h"

static NSString *loadingText = @"Loading...";

enum {
	kUserPermsSection = 0,
	kFriendsPermsSection,
	kExtendedPermsSection,
	kNumberOfSections
};


// Private Interface
@interface GraphApiViewController ()

@property (strong, nonatomic) IBOutlet UIButton *buttonRequest;
@property (strong, nonatomic) IBOutlet UITextField *textObjectID;
@property (strong, nonatomic) IBOutlet UITextView *textOutput;
@property (strong, nonatomic) FBRequestConnection *requestConnection;
@property (strong, nonatomic) IBOutlet UIView *permissionsContainer;
@property (strong, nonatomic) IBOutlet UITableView *permissionsTable;
@property (strong, nonatomic) IBOutlet UITextField *textAccessToken;

- (IBAction)permissionsCancelButton:(id)sender;
- (IBAction)permissionsClearButton:(id)sender;
- (IBAction)permissionsGetAccessTokenButton:(id)sender;
- (IBAction)permissionsSelectAllButton:(id)sender;

- (IBAction)buttonRequestClickHandler:(id)sender;
- (IBAction)showPermissionsButton:(id)sender;

- (void)sendRequest;

- (void)requestCompleted:(FBRequestConnection *)connection
                 forFbID:(NSString *)fbID
                  result:(id)result
                   error:(NSError *)error;

@end




@implementation GraphApiViewController

@synthesize buttonRequest = _buttonRequest;
@synthesize textObjectID = _textObjectID;
@synthesize textOutput = _textOutput;
@synthesize requestConnection = _requestConnection;
@synthesize permissionsContainer = _permissionsContainer;
@synthesize permissionsTable = _permissionsTable;
@synthesize textAccessToken = _textAccessToken;



- (void)dealloc {
    [_requestConnection cancel];
}


#pragma mark - Permissions Helpers

// you can call this with an encoded permission:r/w, or just the permission string, both will work
- (BOOL)getPermissionChecked:(NSString *)permission {
	NSString * theKey = [self extractPermissionTitle:permission];
	NSString * results = [mCheckedPermissions objectForKey:theKey];
	
	return (results != nil);
}

// you can call this with an encoded permission:r/w, or just the permission string, both will work
- (void)setPermissionChecked:(NSString *)permission {
	NSString * theKey = [self extractPermissionTitle:permission];
	[mCheckedPermissions setObject:permission forKey:theKey];
}

// you can call this with an encoded permission:r/w, or just the permission string, both will work
- (void)clearPermissionChecked:(NSString *)permission {
	NSString * theKey = [self extractPermissionTitle:permission];
	[mCheckedPermissions removeObjectForKey:theKey];
}

// TODO: Need to make sure the read / write attribute is correct for each permission.
- (NSArray *)getUserDataPermsArray {
	return @[@"email:r", @"publish_actions:w", @"user_about_me:r", \
		  @"user_actions.books:r", @"user_actions.music:r", @"user_actions.news:r", \
		  @"user_actions.video:r", @"user_activities:r", @"user_birthday:r", \
		  @"user_education_history:r", @"user_events:r", @"user_games_activity:r", \
		  @"user_groups:r", @"user_hometown:r", @"user_interests:r", \
		  @"user_likes:r", @"user_location:r", @"user_notes:r", \
		  @"user_photos:r", @"user_questions:r", @"user_relationship_details:r", \
		  @"user_relationships:r", @"user_religion_politics:r", @"user_status:r", \
		  @"user_subscriptions:r", @"user_videos:r", @"user_website:r", \
		  @"user_work_history:r"];
}


// TODO: Need to make sure the read / write attribute is correct for each permission.
- (NSArray *)getFriendsDataPermsArray {
	return @[@"friends_about_me:r", @"friends_actions.books:r", @"friends_actions.music:r", \
		  @"friends_actions.news:r", @"friends_actions.video:r", @"friends_activities:r", \
		  @"friends_birthday:r", @"friends_education_history:r", @"friends_events:r", \
		  @"friends_games_activity:r", @"friends_groups:r", @"friends_hometown:r", \
		  @"friends_interests:r", @"friends_likes:r", @"friends_location:r", \
		  @"friends_notes:r", @"friends_photos:r", @"friends_questions:r", \
		  @"friends_relationship_details:r", @"friends_relationships:r", @"friends_religion_politics:r", \
		  @"friends_status:r", @"friends_subscriptions:r", @"friends_videos:r", \
		  @"friends_website:r", @"friends_work_history:r"];
}


// TODO: Need to make sure the read / write attribute is correct for each permission.
- (NSArray *)getExtendedDataPermsArray {
	return @[@"ads_management:r", @"create_event:w", @"create_note:w", \
		  @"export_stream:r", @"friends_online_presence:r", @"manage_friendlists:r", \
		  @"manage_notifications:r", @"manage_pages:r", @"photo_upload:r", \
		  @"publish_stream:w", @"read_friendlists:r", @"read_insights:r", \
		  @"read_mailbox:r", @"read_page_mailboxes:r", @"read_requests:r", \
		  @"read_stream:r", @"rsvp_event:r", @"share_item:r", \
		  @"sms:r", @"status_update:r", @"user_online_presence:r", \
		  @"video_upload:r", @"xmpp_login:r"];
}


- (NSArray *)getPermsForSection:(NSInteger)section {
	switch ( section ) {
		case kUserPermsSection:		return [self getUserDataPermsArray];
		case kFriendsPermsSection:	return [self getFriendsDataPermsArray];
		case kExtendedPermsSection:	return [self getExtendedDataPermsArray];
		default: return nil;
	}
}


- (IBAction)permissionsCancelButton:(id)sender {
	_permissionsContainer.hidden = YES;
}

- (IBAction)permissionsClearButton:(id)sender {
	// nuke the current selection
	mCheckedPermissions = [NSMutableDictionary dictionaryWithCapacity:10];
	
	// reload the table (without checkmarks)
	[_permissionsTable reloadData];
}


- (NSString *)extractPermissionTitle:(NSString *)permissionString {
	NSArray * components = [permissionString componentsSeparatedByString:@":"];
	if ( [components count] >= 1 ) {
		return [components objectAtIndex:0];
	}
	
	return @"ERR";
}


- (NSString *)extractPermissionType:(NSString *)permissionString {
	NSArray * components = [permissionString componentsSeparatedByString:@":"];
	if ( [components count] >= 2 ) {
		return [components objectAtIndex:1];
	}
	
	return @"ERR";
}


- (IBAction)permissionsSelectAllButton:(id)sender {
	NSArray * userPerms = [self getUserDataPermsArray];
	NSArray * friendPerms = [self getFriendsDataPermsArray];
	NSArray * extendedPerms = [self getExtendedDataPermsArray];
	
	// start with fresh, empty perms
	mCheckedPermissions = [NSMutableDictionary dictionaryWithCapacity:[userPerms count] + [friendPerms count] + [extendedPerms count]];

	// loop all 3 perms sets, setting them all
	
	for ( NSString * title in userPerms ) {
		[self setPermissionChecked:title];
	}
	
	for ( NSString * title in friendPerms ) {
		[self setPermissionChecked:title];
	}

	for ( NSString * title in extendedPerms ) {
		[self setPermissionChecked:title];
	}
	
	[_permissionsTable reloadData];
}


- (IBAction)permissionsGetAccessTokenButton:(id)sender {
	// try to get the access
	//_permissionsContainer.hidden = YES;
	
	// nuke our old token
	[[FBSession activeSession] closeAndClearTokenInformation];
	_textAccessToken.text = @"Asking...";
	
	// opens it with the current tokens
	[self openFBSession:NO fromPermissionsDialog:YES];
}


- (void)refreshPermissionsDialog {
	FBSession * activeSession = [FBSession activeSession];
	
	if ( activeSession ) {
		_textAccessToken.text = activeSession.accessTokenData.accessToken;
		mCheckedPermissions = [NSMutableDictionary dictionaryWithCapacity:[activeSession.accessTokenData.permissions count]];
		for ( NSString * thePerm in activeSession.accessTokenData.permissions ) {
			[mCheckedPermissions setObject:thePerm forKey:thePerm];
		}
	} else {
		_textAccessToken.text = @"no active FB session. Did you get an error?";
	}
}

//
// main view buttons
//

//
// Show the permissions overlay
//
- (IBAction)showPermissionsButton:(id)sender {
	_permissionsContainer.hidden = NO;
	[self refreshPermissionsDialog];
	[_permissionsTable reloadData];	// make sure it's fresh
}


- (void)openFBSession:(BOOL)withSendRequest fromPermissionsDialog:(BOOL)fromPermissionsDialog {
	NSArray * perms = [NSArray arrayWithArray:[mCheckedPermissions allKeys]];
	
	// TODO: we'll have to update this to seperate out the perms by which array they came from, so we can make read and write requests...
	// or maybe imbed which type they need in the title like "perm:r"  and "perm:w" - Partly done.
	[FBSession openActiveSessionWithPermissions:perms
									   allowLoginUI:YES
								  completionHandler:^(FBSession *session,
													  FBSessionState status,
													  NSError *error) {
									  // if login fails for any reason, we alert
									  if (error) {
										  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
																						  message:error.localizedDescription
																						 delegate:nil
																				cancelButtonTitle:@"OK"
																				otherButtonTitles:nil];
										  [alert show];
										  // if otherwise we check to see if the session is open, an alternative to
										  // to the FB_ISSESSIONOPENWITHSTATE helper-macro would be to check the isOpen
										  // property of the session object; the macros are useful, however, for more
										  // detailed state checking for FBSession objects
									  } else if (FB_ISSESSIONOPENWITHSTATE(status)) {
										  // send our request if we successfully logged in
										  if ( withSendRequest ) {
											  [self sendRequest];
										  }
										  if ( fromPermissionsDialog ) {
											  [self refreshPermissionsDialog];
										  }
									  }
								  }];
}

//
// When the button is clicked, make sure we have a valid session and
// call sendRequests.
//
- (void)buttonRequestClickHandler:(id)sender {
    // FBSample logic
    // Check to see whether we have already opened a session.
    if (FBSession.activeSession.isOpen) {
        // login is integrated with the send button -- so if open, we send
        [self sendRequest];
    } else {
		
		[self openFBSession:YES fromPermissionsDialog:YES];
//		//Modify these permissions to match those you have selected in the Graph API Explorer's "Get Access Token"
//		NSArray * permissions = @[@"basic_info", @"read_stream", @"status_update", @"friends_activities"];
//
//        [FBSession openActiveSessionWithReadPermissions:permissions
//                                           allowLoginUI:YES
//                                      completionHandler:^(FBSession *session,
//                                                          FBSessionState status,
//                                                          NSError *error) {
//                                          // if login fails for any reason, we alert
//                                          if (error) {
//                                              UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
//                                                                                              message:error.localizedDescription
//                                                                                             delegate:nil
//                                                                                    cancelButtonTitle:@"OK"
//                                                                                    otherButtonTitles:nil];
//                                              [alert show];
//                                              // if otherwise we check to see if the session is open, an alternative to
//                                              // to the FB_ISSESSIONOPENWITHSTATE helper-macro would be to check the isOpen
//                                              // property of the session object; the macros are useful, however, for more
//                                              // detailed state checking for FBSession objects
//                                          } else if (FB_ISSESSIONOPENWITHSTATE(status)) {
//                                              // send our request if we successfully logged in
//                                              [self sendRequest];
//                                          }
//                                      }];
    }
}


// FBSample logic
// Read the ids to request from textObjectID and generate a FBRequest
// object for each one.  Add these to the FBRequestConnection and
// then connect to Facebook to get results.  Store the FBRequestConnection
// in case we need to cancel it before it returns.
//
// When a request returns results, call requestComplete:result:error.
//
- (void)sendRequest {
    // extract the id's for which we will request the profile
	NSString * theRequest = self.textObjectID.text;
	
    if ([self.textObjectID.text length] == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"Object ID is required"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }

    self.textOutput.text = loadingText;
    if ([self.textObjectID isFirstResponder]) {
        [self.textObjectID resignFirstResponder];
    }
    
    // create the connection object
    FBRequestConnection *newConnection = [[FBRequestConnection alloc] init];
    
        
	// create a handler block to handle the results of the request
	FBRequestHandler handler =
		^(FBRequestConnection *connection, id result, NSError *error) {
			// output the results of the request
			[self requestCompleted:connection forFbID:theRequest result:result error:error];
		};
	
	// create the request object, using the fbid as the graph path
	// as an alternative the request* static methods of the FBRequest class could
	// be used to fetch common requests, such as /me and /me/friends
	FBRequest *request = [[FBRequest alloc] initWithSession:FBSession.activeSession
												  graphPath:theRequest];
	
	// add the request to the connection object, if more than one request is added
	// the connection object will compose the requests as a batch request; whether or
	// not the request is a batch or a singleton, the handler behavior is the same,
	// allowing the application to be dynamic in regards to whether a single or multiple
	// requests are occuring
	[newConnection addRequest:request completionHandler:handler];
    
    // if there's an outstanding connection, just cancel
    [self.requestConnection cancel];    
    
    // keep track of our connection, and start it
    self.requestConnection = newConnection;    
    [newConnection start];
}

// FBSample logic
// Report any results.  Invoked once for each request we make.
- (void)requestCompleted:(FBRequestConnection *)connection
                 forFbID:fbID
                  result:(id)result
                   error:(NSError *)error {
    // not the completion we were looking for...
    if (self.requestConnection &&
        connection != self.requestConnection) {
        return;
    }
    
    // clean this up, for posterity
    self.requestConnection = nil;

    if ([self.textOutput.text isEqualToString:loadingText]) {
        self.textOutput.text = @"";
    }

    NSString *text;
    if (error) {
        // error contains details about why the request failed
        text = error.localizedDescription;
    } else {
        // result is the json response from a successful request
        NSDictionary *dictionary = (NSDictionary *)result;
        // we pull the name property out, if there is one, and display it
		text = [NSString stringWithFormat:@"%@", dictionary];
    }
    
    self.textOutput.text = [NSString stringWithFormat:@"%@%@: %@\r\n",
                            self.textOutput.text, 
                            [fbID stringByTrimmingCharactersInSet:
                             [NSCharacterSet whitespaceAndNewlineCharacterSet]], 
                            text];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
	_permissionsContainer.hidden = YES;
	_permissionsContainer.frame = self.view.bounds;
	_textObjectID.delegate = self;
	
}

- (void)viewWillAppear:(BOOL)animated {
	// make sure our perms overlay is setup, and happy
	mCheckedPermissions = [NSMutableDictionary dictionaryWithCapacity:10];
	
	// load the saved perms...  or query for them?
}


- (void)viewDidUnload {
	[self setPermissionsTable:nil];
	[self setPermissionsContainer:nil];
	[self setTextAccessToken:nil];
    [super viewDidUnload];
    [self.requestConnection cancel];

    self.buttonRequest = nil;
    self.textObjectID = nil;
    self.textOutput = nil;
    self.requestConnection = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}


#pragma mark - Table View Delegate and Datasource Helpers



- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return kNumberOfSections;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	switch ( section ) {
		case kUserPermsSection:
			return @"User Data Permissions";
			
		case kFriendsPermsSection:
			return @"Friends Data Permissions";
			
		case kExtendedPermsSection:
			return @"Extended Permissions";
			
		default:
			return @"ERR - Invalid Section";
	}
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [[self getPermsForSection:section] count];
}


- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	static NSString *CellIdentifier = @"permissions_cell";

	UITableViewCell *cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		// make a new one
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
		cell.accessoryType = UITableViewCellAccessoryNone;
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		
		cell.textLabel.font = [UIFont systemFontOfSize:16];
		cell.textLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
		cell.textLabel.lineBreakMode = UILineBreakModeTailTruncation;
		cell.textLabel.clipsToBounds = YES;
	} else {
		// refresh it
		cell.accessoryType = UITableViewCellAccessoryNone;
	}

	NSArray * permsArray = [self getPermsForSection:indexPath.section];
	
	if ( indexPath.row < 0 || indexPath.row >= [permsArray count] ) {
		cell.textLabel.text = @"ERR - Invalid Row";
	} else {
		cell.textLabel.text = [self extractPermissionTitle:[permsArray objectAtIndex:indexPath.row]];
		if ( [self getPermissionChecked:cell.textLabel.text] ) {
			cell.accessoryType = UITableViewCellAccessoryCheckmark;	
		}
		
	}
	
	return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	
	// lets not trust the cell, we'll check our backing store, and toggle that too
	if ( [self getPermissionChecked:cell.textLabel.text] ) {
		cell.accessoryType = UITableViewCellAccessoryNone;
		[self clearPermissionChecked:cell.textLabel.text];
	} else {
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
		[self setPermissionChecked:cell.textLabel.text];
	}
	
	return nil;	// lets not actually select the cell
}


#pragma mark - UITextFielddelegate support

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[self buttonRequestClickHandler:_buttonRequest];

	return NO;
}

@end
