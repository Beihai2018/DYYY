//
//  DYYY
//
//  Copyright (c) 2024 huami. All rights reserved.
//  Channel: @huamidev
//  Created on: 2024/10/04
//
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#import "AwemeHeaders.h"
#import "CityManager.h"
#import "DYYYBottomAlertView.h"
#import "DYYYManager.h"

#import "DYYYConstants.h"
#import "DYYYToast.h"

// 顶栏移除
%hook AWEFeedChannelManager

- (void)reloadChannelWithChannelModels:(id)arg1 currentChannelIDList:(id)arg2 reloadType:(id)arg3 selectedChannelID:(id)arg4 {
	NSArray *channelModels = arg1;
	NSMutableArray *newChannelModels = [NSMutableArray array];
	NSArray *currentChannelIDList = arg2;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	NSMutableArray *newCurrentChannelIDList = [NSMutableArray arrayWithArray:currentChannelIDList];

	NSString *hideOtherChannels = [defaults objectForKey:@"DYYYHideOtherChannel"] ?: @"";
	NSArray *hideChannelKeywords = [hideOtherChannels componentsSeparatedByString:@","];

	for (AWEHPTopTabItemModel *tabItemModel in channelModels) {
		NSString *channelID = tabItemModel.channelID;
		NSString *newChannelTitle = tabItemModel.title;
		NSString *oldChannelTitle = tabItemModel.channelTitle;

		if ([channelID isEqualToString:@"homepage_hot_container"]) {
			[newChannelModels addObject:tabItemModel];
			continue;
		}

		BOOL isHideChannel = NO;
		if ([channelID isEqualToString:@"homepage_follow"]) {
			isHideChannel = [defaults boolForKey:@"DYYYHideFollow"];
		} else if ([channelID isEqualToString:@"homepage_mediumvideo"]) {
			isHideChannel = [defaults boolForKey:@"DYYYHideMediumVideo"];
		} else if ([channelID isEqualToString:@"homepage_mall"]) {
			isHideChannel = [defaults boolForKey:@"DYYYHideMall"];
		} else if ([channelID isEqualToString:@"homepage_nearby"]) {
			isHideChannel = [defaults boolForKey:@"DYYYHideNearby"];
		} else if ([channelID isEqualToString:@"homepage_groupon"]) {
			isHideChannel = [defaults boolForKey:@"DYYYHideGroupon"];
		} else if ([channelID isEqualToString:@"homepage_tablive"]) {
			isHideChannel = [defaults boolForKey:@"DYYYHideTabLive"];
		} else if ([channelID isEqualToString:@"homepage_pad_hot"]) {
			isHideChannel = [defaults boolForKey:@"DYYYHidePadHot"];
		} else if ([channelID isEqualToString:@"homepage_hangout"]) {
			isHideChannel = [defaults boolForKey:@"DYYYHideHangout"];
		} else if ([channelID isEqualToString:@"homepage_familiar"]) {
			isHideChannel = [defaults boolForKey:@"DYYYHideFriend"];
		} else if ([channelID isEqualToString:@"homepage_playlet_stream"]) {
			isHideChannel = [defaults boolForKey:@"DYYYHidePlaylet"];
		} else if ([channelID isEqualToString:@"homepage_pad_cinema"]) {
			isHideChannel = [defaults boolForKey:@"DYYYHideCinema"];
		} else if ([channelID isEqualToString:@"homepage_pad_kids_v2"]) {
			isHideChannel = [defaults boolForKey:@"DYYYHideKidsV2"];
		} else if ([channelID isEqualToString:@"homepage_pad_game"]) {
			isHideChannel = [defaults boolForKey:@"DYYYHideGame"];
		}

		if (oldChannelTitle.length > 0 || newChannelTitle.length > 0) {
			for (NSString *keyword in hideChannelKeywords) {
				if (keyword.length > 0 && ([oldChannelTitle containsString:keyword] || [newChannelTitle containsString:keyword])) {
					isHideChannel = YES;
				}
			}
		}

		if (!isHideChannel) {
			[newChannelModels addObject:tabItemModel];
		} else {
			[newCurrentChannelIDList removeObject:channelID];
		}
	}

	%orig(newChannelModels, newCurrentChannelIDList, arg3, arg4);
}

%end

// 关注二次确认
%hook AWEPlayInteractionUserAvatarElement
- (void)onFollowViewClicked:(UITapGestureRecognizer *)gesture {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYfollowTips"]) {

		dispatch_async(dispatch_get_main_queue(), ^{
		  [DYYYBottomAlertView showAlertWithTitle:@"关注确认"
						  message:@"是否确认关注？"
					     cancelAction:nil
					    confirmAction:^{
					      %orig(gesture);
					    }];
		});
	} else {
		%orig;
	}
}

%end

%hook AWEPlayInteractionUserAvatarFollowController
- (void)onFollowViewClicked:(UITapGestureRecognizer *)gesture {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYfollowTips"]) {

		dispatch_async(dispatch_get_main_queue(), ^{
		  [DYYYBottomAlertView showAlertWithTitle:@"关注确认"
						  message:@"是否确认关注？"
					     cancelAction:nil
					    confirmAction:^{
					      %orig(gesture);
					    }];
		});
	} else {
		%orig;
	}
}

%end

// 隐藏底栏加号
%hook AWENormalModeTabBarGeneralPlusButton
+ (id)button {
	BOOL isHiddenJia = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisHiddenJia"];
	if (isHiddenJia) {
		return nil;
	}
	return %orig;
}
%end

// 添加新的 hook 来处理顶栏透明度
%hook AWEFeedTopBarContainer
- (void)layoutSubviews {
	%orig;
	[self applyDYYYTransparency];
}
- (void)didMoveToSuperview {
	%orig;
	[self applyDYYYTransparency];
}
%new
- (void)applyDYYYTransparency {
	NSString *transparentValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYtopbartransparent"];
	if (transparentValue && transparentValue.length > 0) {
		CGFloat alphaValue = [transparentValue floatValue];
		if (alphaValue >= 0.0 && alphaValue <= 1.0) {
			// 设置自身背景色的透明度
			UIColor *backgroundColor = self.backgroundColor;
			if (backgroundColor) {
				CGFloat r, g, b, a;
				if ([backgroundColor getRed:&r green:&g blue:&b alpha:&a]) {
					self.backgroundColor = [UIColor colorWithRed:r green:g blue:b alpha:alphaValue * a];
				}
			}

			// 设置视图的alpha
			[(UIView *)self setAlpha:alphaValue];

			// 确保子视图不会叠加透明度
			for (UIView *subview in self.subviews) {
				subview.alpha = 1.0;
			}
		}
	}
}
%end

// 隐藏视频定位
%hook AWEMarkView

- (void)layoutSubviews {
	%orig;

	UIViewController *vc = [self firstAvailableUIViewController];

	if ([vc isKindOfClass:%c(AWEPlayInteractionViewController)]) {
		if (self.markLabel) {
			self.markLabel.textColor = [UIColor whiteColor];
		}
	}

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideLocation"]) {
		self.hidden = YES;
		return;
	}
}

%end

// 双指长按菜单
%group DYYYSettingsGesture

%hook UIWindow
- (instancetype)initWithFrame:(CGRect)frame {
	UIWindow *window = %orig(frame);
	if (window) {
		UILongPressGestureRecognizer *doubleFingerLongPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleFingerLongPressGesture:)];
		doubleFingerLongPressGesture.numberOfTouchesRequired = 2;
		[window addGestureRecognizer:doubleFingerLongPressGesture];
	}
	return window;
}

%new
- (void)handleDoubleFingerLongPressGesture:(UILongPressGestureRecognizer *)gesture {
	if (gesture.state == UIGestureRecognizerStateBegan) {
		UIViewController *rootViewController = self.rootViewController;
		if (rootViewController) {
			UIViewController *settingVC = [[DYYYSettingViewController alloc] init];

			if (settingVC) {
				BOOL isIPad = UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad;
				if (@available(iOS 15.0, *)) {
					if (!isIPad) {
						settingVC.modalPresentationStyle = UIModalPresentationPageSheet;
					} else {
						settingVC.modalPresentationStyle = UIModalPresentationFullScreen;
					}
				} else {
					settingVC.modalPresentationStyle = UIModalPresentationFullScreen;
				}

				if (settingVC.modalPresentationStyle == UIModalPresentationFullScreen) {
					UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
					[closeButton setTitle:@"关闭" forState:UIControlStateNormal];
					closeButton.translatesAutoresizingMaskIntoConstraints = NO;

					[settingVC.view addSubview:closeButton];

					[NSLayoutConstraint activateConstraints:@[
						[closeButton.trailingAnchor constraintEqualToAnchor:settingVC.view.trailingAnchor constant:-10],
						[closeButton.topAnchor constraintEqualToAnchor:settingVC.view.topAnchor constant:40], [closeButton.widthAnchor constraintEqualToConstant:80],
						[closeButton.heightAnchor constraintEqualToConstant:40]
					]];

					[closeButton addTarget:self action:@selector(closeSettings:) forControlEvents:UIControlEventTouchUpInside];
				}

				UIView *handleBar = [[UIView alloc] init];
				handleBar.backgroundColor = [UIColor whiteColor];
				handleBar.layer.cornerRadius = 2.5;
				handleBar.translatesAutoresizingMaskIntoConstraints = NO;
				[settingVC.view addSubview:handleBar];

				[NSLayoutConstraint activateConstraints:@[
					[handleBar.centerXAnchor constraintEqualToAnchor:settingVC.view.centerXAnchor],
					[handleBar.topAnchor constraintEqualToAnchor:settingVC.view.topAnchor constant:8], [handleBar.widthAnchor constraintEqualToConstant:40],
					[handleBar.heightAnchor constraintEqualToConstant:5]
				]];

				[rootViewController presentViewController:settingVC animated:YES completion:nil];
			}
		}
	}
}

%new
- (void)closeSettings:(UIButton *)button {
	[button.superview.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
}
%end

%end

%hook UIView
// 关键方法,误删！
%new
- (UIViewController *)firstAvailableUIViewController {
	UIResponder *responder = [self nextResponder];
	while (responder != nil) {
		if ([responder isKindOfClass:[UIViewController class]]) {
			return (UIViewController *)responder;
		}
		responder = [responder nextResponder];
	}
	return nil;
}

%end

// 收藏二次确认
%hook AWEFeedVideoButton
- (id)touchUpInsideBlock {
	id r = %orig;

	// 只有收藏按钮才显示确认弹窗
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYcollectTips"] && [self.accessibilityLabel isEqualToString:@"收藏"]) {

		dispatch_async(dispatch_get_main_queue(), ^{
		  [DYYYBottomAlertView showAlertWithTitle:@"收藏确认"
						  message:@"是否确认/取消收藏？"
					     cancelAction:nil
					    confirmAction:^{
					      if (r && [r isKindOfClass:NSClassFromString(@"NSBlock")]) {
						      ((void (^)(void))r)();
					      }
					    }];
		});

		return nil; // 阻止原始 block 立即执行
	}

	return r;
}
%end

// 进度条样式
%hook AWEFeedProgressSlider

// layoutSubviews 保持不变
- (void)layoutSubviews {
	%orig;
	[self applyCustomProgressStyle];
}

%new

- (void)applyCustomProgressStyle {
	NSString *scheduleStyle = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYScheduleStyle"];
	UIView *parentView = self.superview;

	if (!parentView)
		return;

	if ([scheduleStyle isEqualToString:@"进度条两侧左右"]) {
		// 尝试获取标签
		UILabel *leftLabel = [parentView viewWithTag:10001];
		UILabel *rightLabel = [parentView viewWithTag:10002];

		if (leftLabel && rightLabel) {
			CGFloat padding = 5.0;
			CGFloat sliderY = self.frame.origin.y;
			CGFloat sliderHeight = self.frame.size.height;
			CGFloat sliderX = leftLabel.frame.origin.x + leftLabel.frame.size.width + padding;
			CGFloat sliderWidth = rightLabel.frame.origin.x - padding - sliderX;

			if (sliderWidth < 0)
				sliderWidth = 0;

			self.frame = CGRectMake(sliderX, sliderY, sliderWidth, sliderHeight);
		} else {
			CGFloat fallbackWidthPercent = 0.80;
			CGFloat parentWidth = parentView.bounds.size.width;
			CGFloat fallbackWidth = parentWidth * fallbackWidthPercent;
			CGFloat fallbackX = (parentWidth - fallbackWidth) / 2.0;
			// 使用 self.frame 获取当前 Y 和 Height (通常由 %orig 设置)
			CGFloat currentY = self.frame.origin.y;
			CGFloat currentHeight = self.frame.size.height;
			// 应用回退 frame
			self.frame = CGRectMake(fallbackX, currentY, fallbackWidth, currentHeight);
		}
	} else {
	}
}

- (void)setAlpha:(CGFloat)alpha {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisShowScheduleDisplay"]) {
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideVideoProgress"]) {
			%orig(0);
		} else {
			%orig(1.0);
		}
	} else {
		%orig;
	}
}

static CGFloat leftLabelLeftMargin = -1;
static CGFloat rightLabelRightMargin = -1;

- (void)setLimitUpperActionArea:(BOOL)arg1 {
	%orig;

	NSString *durationFormatted = [self.progressSliderDelegate formatTimeFromSeconds:floor(self.progressSliderDelegate.model.videoDuration / 1000)];

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisShowScheduleDisplay"]) {
		UIView *parentView = self.superview;
		if (!parentView)
			return;

		[[parentView viewWithTag:10001] removeFromSuperview];
		[[parentView viewWithTag:10002] removeFromSuperview];

		CGRect sliderOriginalFrameInParent = [self convertRect:self.bounds toView:parentView];
		CGRect sliderFrame = self.frame;

		CGFloat verticalOffset = -12.5;
		NSString *offsetValueString = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYTimelineVerticalPosition"];
		if (offsetValueString.length > 0) {
			CGFloat configOffset = [offsetValueString floatValue];
			if (configOffset != 0)
				verticalOffset = configOffset;
		}

		NSString *scheduleStyle = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYScheduleStyle"];
		BOOL showRemainingTime = [scheduleStyle isEqualToString:@"进度条右侧剩余"];
		BOOL showCompleteTime = [scheduleStyle isEqualToString:@"进度条右侧完整"];
		BOOL showLeftRemainingTime = [scheduleStyle isEqualToString:@"进度条左侧剩余"];
		BOOL showLeftCompleteTime = [scheduleStyle isEqualToString:@"进度条左侧完整"];

		NSString *labelColorHex = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYProgressLabelColor"];
		UIColor *labelColor = [UIColor whiteColor];
		if (labelColorHex && labelColorHex.length > 0) {
			SEL colorSelector = NSSelectorFromString(@"colorWithHexString:");
			Class dyyyManagerClass = NSClassFromString(@"DYYYManager");
			if (dyyyManagerClass && [dyyyManagerClass respondsToSelector:colorSelector]) {
				labelColor = [dyyyManagerClass performSelector:colorSelector withObject:labelColorHex];
			}
		}

		CGFloat labelYPosition = sliderOriginalFrameInParent.origin.y + verticalOffset;
		CGFloat labelHeight = 15.0;
		UIFont *labelFont = [UIFont systemFontOfSize:8];

		if (!showRemainingTime && !showCompleteTime) {
			UILabel *leftLabel = [[UILabel alloc] init];
			leftLabel.backgroundColor = [UIColor clearColor];
			leftLabel.textColor = labelColor;
			leftLabel.font = labelFont;
			leftLabel.tag = 10001;
			if (showLeftRemainingTime)
				leftLabel.text = @"00:00";
			else if (showLeftCompleteTime)
				leftLabel.text = [NSString stringWithFormat:@"00:00/%@", durationFormatted];
			else
				leftLabel.text = @"00:00";

			[leftLabel sizeToFit];

			if (leftLabelLeftMargin == -1) {
				leftLabelLeftMargin = sliderFrame.origin.x;
			}

			leftLabel.frame = CGRectMake(leftLabelLeftMargin, labelYPosition, leftLabel.frame.size.width, labelHeight);
			[parentView addSubview:leftLabel];
		}

		if (!showLeftRemainingTime && !showLeftCompleteTime) {
			UILabel *rightLabel = [[UILabel alloc] init];
			rightLabel.backgroundColor = [UIColor clearColor];
			rightLabel.textColor = labelColor;
			rightLabel.font = labelFont;
			rightLabel.tag = 10002;
			if (showRemainingTime)
				rightLabel.text = @"00:00";
			else if (showCompleteTime)
				rightLabel.text = [NSString stringWithFormat:@"00:00/%@", durationFormatted];
			else
				rightLabel.text = durationFormatted;

			[rightLabel sizeToFit];

			if (rightLabelRightMargin == -1) {
				rightLabelRightMargin = sliderFrame.origin.x + sliderFrame.size.width - rightLabel.frame.size.width;
			}

			rightLabel.frame = CGRectMake(rightLabelRightMargin, labelYPosition, rightLabel.frame.size.width, labelHeight);
			[parentView addSubview:rightLabel];
		}

		[self setNeedsLayout];
	} else {
		UIView *parentView = self.superview;
		if (parentView) {
			[[parentView viewWithTag:10001] removeFromSuperview];
			[[parentView viewWithTag:10002] removeFromSuperview];
		}
		[self setNeedsLayout];
	}
}

%end

%hook AWEPlayInteractionProgressController

%new
- (NSString *)formatTimeFromSeconds:(CGFloat)seconds {
	NSInteger hours = (NSInteger)seconds / 3600;
	NSInteger minutes = ((NSInteger)seconds % 3600) / 60;
	NSInteger secs = (NSInteger)seconds % 60;

	if (hours > 0) {
		return [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)hours, (long)minutes, (long)secs];
	} else {
		return [NSString stringWithFormat:@"%02ld:%02ld", (long)minutes, (long)secs];
	}
}

- (void)updateProgressSliderWithTime:(CGFloat)arg1 totalDuration:(CGFloat)arg2 {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisShowScheduleDisplay"]) {
		AWEFeedProgressSlider *progressSlider = self.progressSlider;
		UIView *parentView = progressSlider.superview;
		if (!parentView)
			return;

		UILabel *leftLabel = [parentView viewWithTag:10001];
		UILabel *rightLabel = [parentView viewWithTag:10002];

		NSString *labelColorHex = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYProgressLabelColor"];
		UIColor *labelColor = [UIColor whiteColor];
		if (labelColorHex && labelColorHex.length > 0) {
			SEL colorSelector = NSSelectorFromString(@"colorWithHexString:");
			Class dyyyManagerClass = NSClassFromString(@"DYYYManager");
			if (dyyyManagerClass && [dyyyManagerClass respondsToSelector:colorSelector]) {
				labelColor = [dyyyManagerClass performSelector:colorSelector withObject:labelColorHex];
			}
		}
		NSString *scheduleStyle = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYScheduleStyle"];
		BOOL showRemainingTime = [scheduleStyle isEqualToString:@"进度条右侧剩余"];
		BOOL showCompleteTime = [scheduleStyle isEqualToString:@"进度条右侧完整"];
		BOOL showLeftRemainingTime = [scheduleStyle isEqualToString:@"进度条左侧剩余"];
		BOOL showLeftCompleteTime = [scheduleStyle isEqualToString:@"进度条左侧完整"];

		// 更新左标签
		if (arg1 >= 0 && leftLabel) {
			NSString *newLeftText = @"";
			if (showLeftRemainingTime) {
				CGFloat remainingTime = arg2 - arg1;
				if (remainingTime < 0)
					remainingTime = 0;
				newLeftText = [self formatTimeFromSeconds:remainingTime];
			} else if (showLeftCompleteTime) {
				newLeftText = [NSString stringWithFormat:@"%@/%@", [self formatTimeFromSeconds:arg1], [self formatTimeFromSeconds:arg2]];
			} else {
				newLeftText = [self formatTimeFromSeconds:arg1];
			}

			if (![leftLabel.text isEqualToString:newLeftText]) {
				leftLabel.text = newLeftText;
				[leftLabel sizeToFit];
				CGRect leftFrame = leftLabel.frame;
				leftFrame.size.height = 15.0;
				leftLabel.frame = leftFrame;
			}
			leftLabel.textColor = labelColor;
		}

		// 更新右标签
		if (arg2 > 0 && rightLabel) {
			NSString *newRightText = @"";
			if (showRemainingTime) {
				CGFloat remainingTime = arg2 - arg1;
				if (remainingTime < 0)
					remainingTime = 0;
				newRightText = [self formatTimeFromSeconds:remainingTime];
			} else if (showCompleteTime) {
				newRightText = [NSString stringWithFormat:@"%@/%@", [self formatTimeFromSeconds:arg1], [self formatTimeFromSeconds:arg2]];
			} else {
				newRightText = [self formatTimeFromSeconds:arg2];
			}

			if (![rightLabel.text isEqualToString:newRightText]) {
				rightLabel.text = newRightText;
				[rightLabel sizeToFit];
				CGRect rightFrame = rightLabel.frame;
				rightFrame.size.height = 15.0;
				rightLabel.frame = rightFrame;
			}
			rightLabel.textColor = labelColor;
		}
	}
}

- (void)setHidden:(BOOL)hidden {
	%orig;
	BOOL hideVideoProgress = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideVideoProgress"];
	BOOL showScheduleDisplay = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisShowScheduleDisplay"];
	if (hideVideoProgress && showScheduleDisplay && !hidden) {
		self.alpha = 0;
	}
}

%end

%hook AWEFakeProgressSliderView
- (void)layoutSubviews {
	%orig;
	[self applyCustomProgressStyle];
}

%new
- (void)applyCustomProgressStyle {
	NSString *scheduleStyle = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYScheduleStyle"];

	if ([scheduleStyle isEqualToString:@"进度条两侧左右"]) {
		for (UIView *subview in self.subviews) {
			if ([subview class] == [UIView class]) {
				subview.hidden = YES;
			}
		}
	}
}
%end

// 隐藏底栏按钮
%hook AWENormalModeTabBarTextView

- (void)layoutSubviews {
	%orig;

	NSString *indexTitle = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYIndexTitle"];
	NSString *friendsTitle = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYFriendsTitle"];
	NSString *msgTitle = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYMsgTitle"];
	NSString *selfTitle = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYSelfTitle"];

	for (UIView *subview in [self subviews]) {
		if ([subview isKindOfClass:[UILabel class]]) {
			UILabel *label = (UILabel *)subview;
			if ([label.text isEqualToString:@"首页"]) {
				if (indexTitle.length > 0) {
					[label setText:indexTitle];
					[self setNeedsLayout];
				}
			}
			if ([label.text isEqualToString:@"朋友"]) {
				if (friendsTitle.length > 0) {
					[label setText:friendsTitle];
					[self setNeedsLayout];
				}
			}
			if ([label.text isEqualToString:@"消息"]) {
				if (msgTitle.length > 0) {
					[label setText:msgTitle];
					[self setNeedsLayout];
				}
			}
			if ([label.text isEqualToString:@"我"]) {
				if (selfTitle.length > 0) {
					[label setText:selfTitle];
					[self setNeedsLayout];
				}
			}
		}
	}
}
%end

// 时间属地显示
%hook AWEPlayInteractionTimestampElement
- (id)timestampLabel {
	UILabel *label = %orig;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableArea"]) {
		NSString *text = label.text;
		NSString *cityCode = self.model.cityCode;

		if (cityCode.length > 0) {
			NSString *cityName = [CityManager.sharedInstance getCityNameWithCode:cityCode];
			NSString *provinceName = [CityManager.sharedInstance getProvinceNameWithCode:cityCode];
			// 使用 GeoNames API
			if (!cityName || cityName.length == 0) {
				NSString *cacheKey = cityCode;

				static NSCache *geoNamesCache = nil;
				static dispatch_once_t onceToken;
				dispatch_once(&onceToken, ^{
				  geoNamesCache = [[NSCache alloc] init];
				  geoNamesCache.name = @"com.dyyy.geonames.cache";
				  geoNamesCache.countLimit = 1000;
				});

				NSDictionary *cachedData = [geoNamesCache objectForKey:cacheKey];

				if (!cachedData) {
					NSString *cachesDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
					NSString *geoNamesCacheDir = [cachesDir stringByAppendingPathComponent:@"DYYYGeoNamesCache"];

					NSFileManager *fileManager = [NSFileManager defaultManager];
					if (![fileManager fileExistsAtPath:geoNamesCacheDir]) {
						[fileManager createDirectoryAtPath:geoNamesCacheDir withIntermediateDirectories:YES attributes:nil error:nil];
					}

					NSString *cacheFilePath = [geoNamesCacheDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", cacheKey]];

					if ([fileManager fileExistsAtPath:cacheFilePath]) {
						cachedData = [NSDictionary dictionaryWithContentsOfFile:cacheFilePath];
						if (cachedData) {
							[geoNamesCache setObject:cachedData forKey:cacheKey];
						}
					}
				}

				if (cachedData) {
					NSString *countryName = cachedData[@"countryName"];
					NSString *adminName1 = cachedData[@"adminName1"];
					NSString *localName = cachedData[@"name"];
					NSString *displayLocation = @"未知";

					if (countryName.length > 0) {
						if (adminName1.length > 0 && localName.length > 0 && ![countryName isEqualToString:@"中国"] && ![countryName isEqualToString:localName]) {
							// 国外位置：国家 + 州/省 + 地点
							displayLocation = [NSString stringWithFormat:@"%@ %@ %@", countryName, adminName1, localName];
						} else if (localName.length > 0 && ![countryName isEqualToString:localName]) {
							// 只有国家和地点名
							displayLocation = [NSString stringWithFormat:@"%@ %@", countryName, localName];
						} else {
							// 只有国家名
							displayLocation = countryName;
						}
					} else if (localName.length > 0) {
						displayLocation = localName;
					}

					dispatch_async(dispatch_get_main_queue(), ^{
					  NSString *currentText = label.text ?: @"";

					  if ([currentText containsString:@"IP属地："]) {
						  NSRange range = [currentText rangeOfString:@"IP属地："];
						  if (range.location != NSNotFound) {
							  NSString *baseText = [currentText substringToIndex:range.location];
							  if (![currentText containsString:displayLocation]) {
								  label.text = [NSString stringWithFormat:@"%@IP属地：%@", baseText, displayLocation];
							  }
						  }
					  } else {
						  NSString *baseText = label.text ?: @"";
						  if (baseText.length > 0) {
							  label.text = [NSString stringWithFormat:@"%@  IP属地：%@", baseText, displayLocation];
						  }
					  }
					});
				} else {
					[CityManager
					    fetchLocationWithGeonameId:cityCode
						     completionHandler:^(NSDictionary *locationInfo, NSError *error) {
						       if (locationInfo) {
							       NSString *countryName = locationInfo[@"countryName"];
							       NSString *adminName1 = locationInfo[@"adminName1"]; // 州/省级名称
							       NSString *localName = locationInfo[@"name"];	   // 当前地点名称
							       NSString *displayLocation = @"未知";

							       // 根据返回数据构建位置显示文本
							       if (countryName.length > 0) {
								       if (adminName1.length > 0 && localName.length > 0 && ![countryName isEqualToString:@"中国"] &&
									   ![countryName isEqualToString:localName]) {
									       // 国外位置：国家 + 州/省 + 地点
									       displayLocation = [NSString stringWithFormat:@"%@ %@ %@", countryName, adminName1, localName];
								       } else if (localName.length > 0 && ![countryName isEqualToString:localName]) {
									       // 只有国家和地点名
									       displayLocation = [NSString stringWithFormat:@"%@ %@", countryName, localName];
								       } else {
									       // 只有国家名
									       displayLocation = countryName;
								       }
							       } else if (localName.length > 0) {
								       displayLocation = localName;
							       }

							       // 修改：仅当位置不为"未知"时才缓存
							       if (![displayLocation isEqualToString:@"未知"]) {
								       [geoNamesCache setObject:locationInfo forKey:cacheKey];

								       NSString *cachesDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
								       NSString *geoNamesCacheDir = [cachesDir stringByAppendingPathComponent:@"DYYYGeoNamesCache"];
								       NSString *cacheFilePath = [geoNamesCacheDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", cacheKey]];

								       [locationInfo writeToFile:cacheFilePath atomically:YES];
							       }

							       dispatch_async(dispatch_get_main_queue(), ^{
								 NSString *currentText = label.text ?: @"";

								 if ([currentText containsString:@"IP属地："]) {
									 NSRange range = [currentText rangeOfString:@"IP属地："];
									 if (range.location != NSNotFound) {
										 NSString *baseText = [currentText substringToIndex:range.location];
										 if (![currentText containsString:displayLocation]) {
											 label.text = [NSString stringWithFormat:@"%@IP属地：%@", baseText, displayLocation];
										 }
									 }
								 } else {
									 NSString *baseText = label.text ?: @"";
									 if (baseText.length > 0) {
										 label.text = [NSString stringWithFormat:@"%@  IP属地：%@", baseText, displayLocation];
									 }
								 }
							       });
						       }
						     }];
				}
			} else if (![text containsString:cityName]) {
				if (!self.model.ipAttribution) {
					BOOL isDirectCity = [provinceName isEqualToString:cityName] ||
							    ([cityCode hasPrefix:@"11"] || [cityCode hasPrefix:@"12"] || [cityCode hasPrefix:@"31"] || [cityCode hasPrefix:@"50"]);

					if (isDirectCity) {
						label.text = [NSString stringWithFormat:@"%@  IP属地：%@", text, cityName];
					} else {
						label.text = [NSString stringWithFormat:@"%@  IP属地：%@ %@", text, provinceName, cityName];
					}
				} else {
					BOOL isDirectCity = [provinceName isEqualToString:cityName] ||
							    ([cityCode hasPrefix:@"11"] || [cityCode hasPrefix:@"12"] || [cityCode hasPrefix:@"31"] || [cityCode hasPrefix:@"50"]);

					BOOL containsProvince = [text containsString:provinceName];
					if (containsProvince && !isDirectCity) {
						label.text = [NSString stringWithFormat:@"%@ %@", text, cityName];
					} else if (containsProvince && isDirectCity) {
						label.text = [NSString stringWithFormat:@"%@  IP属地：%@", text, cityName];
					} else if (isDirectCity && containsProvince) {
						label.text = text;
					} else if (containsProvince) {
						label.text = [NSString stringWithFormat:@"%@ %@", text, cityName];
					} else {
						label.text = text;
					}
				}
			}
		}
	}
	return label;
}

+ (BOOL)shouldActiveWithData:(id)arg1 context:(id)arg2 {
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableArea"];
}

%end

// 右侧按钮图标
%hook AWEFeedVideoButton

- (void)setImage:(id)arg1 {
	NSString *nameString = nil;

	if ([self respondsToSelector:@selector(imageNameString)]) {
		nameString = [self performSelector:@selector(imageNameString)];
	}

	if (!nameString) {
		%orig;
		return;
	}

	NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
	NSString *dyyyFolderPath = [documentsPath stringByAppendingPathComponent:@"DYYY"];

	[[NSFileManager defaultManager] createDirectoryAtPath:dyyyFolderPath withIntermediateDirectories:YES attributes:nil error:nil];

	NSDictionary *iconMapping = @{
		@"icon_home_like_after" : @"like_after.png",
		@"icon_home_like_before" : @"like_before.png",
		@"icon_home_comment" : @"comment.png",
		@"icon_home_unfavorite" : @"unfavorite.png",
		@"icon_home_favorite" : @"favorite.png",
		@"iconHomeShareRight" : @"share.png"
	};

	NSString *customFileName = nil;
	if ([nameString containsString:@"_comment"]) {
		customFileName = @"comment.png";
	} else if ([nameString containsString:@"_like"]) {
		customFileName = @"like_before.png";
	} else if ([nameString containsString:@"_collect"]) {
		customFileName = @"unfavorite.png";
	} else if ([nameString containsString:@"_share"]) {
		customFileName = @"share.png";
	}

	for (NSString *prefix in iconMapping.allKeys) {
		if ([nameString hasPrefix:prefix]) {
			customFileName = iconMapping[prefix];
			break;
		}
	}

	if (customFileName) {
		NSString *customImagePath = [dyyyFolderPath stringByAppendingPathComponent:customFileName];

		if ([[NSFileManager defaultManager] fileExistsAtPath:customImagePath]) {
			UIImage *customImage = [UIImage imageWithContentsOfFile:customImagePath];
			if (customImage) {
				CGFloat targetWidth = 44.0;
				CGFloat targetHeight = 44.0;
				CGSize originalSize = customImage.size;

				CGFloat scale = MIN(targetWidth / originalSize.width, targetHeight / originalSize.height);
				CGFloat newWidth = originalSize.width * scale;
				CGFloat newHeight = originalSize.height * scale;

				UIGraphicsBeginImageContextWithOptions(CGSizeMake(newWidth, newHeight), NO, 0.0);
				[customImage drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
				UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
				UIGraphicsEndImageContext();

				if (resizedImage) {
					%orig(resizedImage);
					return;
				}
			}
		}
	}

	%orig;
}

%end

// 获取资源的地址
%hook AWEURLModel
%new - (NSURL *)getDYYYSrcURLDownload {
	NSURL *bestURL;
	for (NSString *url in self.originURLList) {
		if ([url containsString:@"video_mp4"] || [url containsString:@".jpeg"] || [url containsString:@".mp3"]) {
			bestURL = [NSURL URLWithString:url];
		}
	}

	if (bestURL == nil) {
		bestURL = [NSURL URLWithString:[self.originURLList firstObject]];
	}

	return bestURL;
}
%end

// 禁用点击首页刷新
%hook AWENormalModeTabBarGeneralButton

- (BOOL)enableRefresh {
	if ([self.accessibilityLabel isEqualToString:@"首页"]) {
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYDisableHomeRefresh"]) {
			return NO;
		}
	}
	return %orig;
}

%end

// 屏蔽版本更新
%hook AWEVersionUpdateManager

- (void)startVersionUpdateWorkflow:(id)arg1 completion:(id)arg2 {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYNoUpdates"]) {
		if (arg2) {
			void (^completionBlock)(void) = arg2;
			completionBlock();
		}
	} else {
		%orig;
	}
}

- (id)workflow {
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYNoUpdates"] ? nil : %orig;
}

- (id)badgeModule {
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYNoUpdates"] ? nil : %orig;
}

%end

// 双击菜单毛玻璃效果
%hook AWEUserActionSheetView

- (void)layoutSubviews {
	%orig;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableSheetBlur"]) {
		[self applyBlurEffectAndWhiteText];
	}
}

%new
- (void)applyBlurEffectAndWhiteText {
	// 应用毛玻璃效果到容器视图
	if (self.containerView) {
		self.containerView.backgroundColor = [UIColor clearColor];

		for (UIView *subview in self.containerView.subviews) {
			if ([subview isKindOfClass:[UIVisualEffectView class]] && subview.tag == 9999) {
				[subview removeFromSuperview];
			}
		}

		// 动态获取用户设置的透明度
		float userTransparency = [[[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYSheetBlurTransparent"] floatValue];
		if (userTransparency <= 0 || userTransparency > 1) {
			userTransparency = 0.9; // 默认值0.9
		}

		UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
		UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
		blurEffectView.frame = self.containerView.bounds;
		blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		blurEffectView.alpha = userTransparency; // 设置为用户自定义透明度
		blurEffectView.tag = 9999;

		[self.containerView insertSubview:blurEffectView atIndex:0];

		[self setTextColorWhiteRecursivelyInView:self.containerView];
	}
}

%new
- (void)setTextColorWhiteRecursivelyInView:(UIView *)view {
	for (UIView *subview in view.subviews) {
		if (![subview isKindOfClass:[UIVisualEffectView class]]) {
			subview.backgroundColor = [UIColor clearColor];
		}

		if ([subview isKindOfClass:[UILabel class]]) {
			UILabel *label = (UILabel *)subview;
			label.textColor = [UIColor whiteColor];
		}

		if ([subview isKindOfClass:[UIButton class]]) {
			UIButton *button = (UIButton *)subview;
			[button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
		}

		[self setTextColorWhiteRecursivelyInView:subview];
	}
}
%end

// 长按评论复制文案
%hook _TtC33AWECommentLongPressPanelSwiftImpl32CommentLongPressPanelCopyElement

- (void)elementTapped {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYCommentCopyText"]) {
		AWECommentLongPressPanelContext *commentPageContext = [self commentPageContext];
		AWECommentModel *selectdComment = [commentPageContext selectdComment];
		if (!selectdComment) {
			AWECommentLongPressPanelParam *params = [commentPageContext params];
			selectdComment = [params selectdComment];
		}
		NSString *descText = [selectdComment content];
		[[UIPasteboard generalPasteboard] setString:descText];
		[DYYYToast showSuccessToastWithMessage:@"评论已复制"];
	}
}
%end

// 禁用个人资料自动进入橱窗
%hook AWEUserTabListModel

- (NSInteger)profileLandingTab {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYDefaultEnterWorks"]) {
		return 0;
	} else {
		return %orig;
	}
}

%end

// 自动播放tab逻辑
%group AutoPlay

%hook DUXToast

+ (void)showText:(NSString *)text {
	if (text && [text isEqualToString:@"已取消自动翻页"]) {
		return;
	}
	%orig;
}

%end

%hook UIViewController

- (void)viewDidAppear:(BOOL)animated {
	%orig;
	if ([self isKindOfClass:%c(AWESearchViewController)] || [self isKindOfClass:%c(IESLiveInnerFeedViewController)] ||
	    [self isKindOfClass:%c(AWEAwemeDetailTableViewController)]) {
		UITabBarController *tabBarController = self.tabBarController;
		if ([tabBarController isKindOfClass:%c(AWENormalModeTabBarController)]) {
			tabBarController.tabBar.hidden = YES;
		}
	}
}

%end

%hook AWENormalModeTabBarController

- (void)viewDidLoad {
	%orig;

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
}

%new
- (void)handleApplicationWillEnterForeground:(NSNotification *)notification {
	UIViewController *topVC = topVC;
	if ([topVC isKindOfClass:%c(UINavigationController)]) {
		UINavigationController *navVC = (UINavigationController *)topVC;
		topVC = navVC.topViewController;
	}

	if ([topVC isKindOfClass:%c(AWESearchViewController)] || [topVC isKindOfClass:%c(IESLiveInnerFeedViewController)] ||
	    [topVC isKindOfClass:%c(AWEAwemeDetailTableViewController)]) {
		self.awe_tabBar.hidden = YES;
	}
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	%orig;
}

%end

// 启用自动播放
%hook AWEFeedGuideManager

- (bool)enableAutoplay {
	BOOL featureEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableAutoPlay"];
	if (!featureEnabled) {
		return %orig;
	}
	return YES;
}

%end

%hook AWEFeedIPhoneAutoPlayManager

- (BOOL)isAutoPlayOpen {
	return YES;
}

%end

%hook AWEFeedModuleService

- (BOOL)getFeedIphoneAutoPlayState {
	return YES;
}
%end

%hook AWEFeedIPhoneAutoPlayManager

- (BOOL)getFeedIphoneAutoPlayState {
	BOOL r = %orig;
	return YES;
}
%end

%end

// 设置长按倍数
%hook AWEPlayInteractionSpeedController

static BOOL hasChangedSpeed = NO;

- (CGFloat)longPressFastSpeedValue {
	float longPressSpeed = [[NSUserDefaults standardUserDefaults] floatForKey:@"DYYYLongPressSpeed"];
	if (longPressSpeed == 0) {
		longPressSpeed = 2.0;
	}
	return longPressSpeed;
}

- (void)changeSpeed:(double)speed {
    float longPressSpeed = [[NSUserDefaults standardUserDefaults] floatForKey:@"DYYYLongPressSpeed"];
    
    if (speed == 2.0) {
        if (!hasChangedSpeed) {
            if (longPressSpeed != 0 && longPressSpeed != 2.0) {
                hasChangedSpeed = YES;
                %orig(longPressSpeed);
                return;
            }
        } else {
            hasChangedSpeed = NO;
            %orig(1.0);
            return;
        }
    }
    
    if (longPressSpeed == 0 || longPressSpeed == 2) {
        %orig(speed);
        return;
    }
}


%end

%hook UILabel

- (void)setText:(NSString *)text {
	UIView *superview = self.superview;

	if ([superview isKindOfClass:%c(AFDFastSpeedView)] && text) {
		float longPressSpeed = [[NSUserDefaults standardUserDefaults] floatForKey:@"DYYYLongPressSpeed"];
		if (longPressSpeed == 0) {
			longPressSpeed = 2.0;
		}

		NSString *speedString = [NSString stringWithFormat:@"%.2f", longPressSpeed];
		if ([speedString hasSuffix:@".00"]) {
			speedString = [speedString substringToIndex:speedString.length - 3];
		} else if ([speedString hasSuffix:@"0"] && [speedString containsString:@"."]) {
			speedString = [speedString substringToIndex:speedString.length - 1];
		}

		if ([text containsString:@"2"]) {
			text = [text stringByReplacingOccurrencesOfString:@"2" withString:speedString];
		}
	}

	%orig(text);
}
%end

// 移除评论实况水印
%hook AWECommentMediaDownloadConfigLivePhoto

bool commentLivePhotoNotWaterMark = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYCommentLivePhotoNotWaterMark"];

- (bool)needClientWaterMark {
	return commentLivePhotoNotWaterMark ? 0 : %orig;
}

- (bool)needClientEndWaterMark {
	return commentLivePhotoNotWaterMark ? 0 : %orig;
}

- (id)watermarkConfig {
	return commentLivePhotoNotWaterMark ? nil : %orig;
}

%end

// 移除评论图片水印
%hook AWECommentImageModel
- (id)downloadUrl {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYCommentNotWaterMark"]) {
		return self.originUrl;
	}
	return %orig;
}
%end

// 强制启用保存他人头像
%hook AFDProfileAvatarFunctionManager
- (BOOL)shouldShowSaveAvatarItem {
	BOOL shouldEnable = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYEnableSaveAvatar"];
	if (shouldEnable) {
		return YES;
	}
	return %orig;
}
%end

%hook AWEFeedTabJumpGuideView

- (void)layoutSubviews {
	%orig;
	[self removeFromSuperview];
}

%end

// 隐藏头像按钮
%hook AWEFeedLiveMarkView
- (void)setHidden:(BOOL)hidden {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideAvatarButton"]) {
		hidden = YES;
	}

	%orig(hidden);
}
%end

// 隐藏底栏评论
%hook AWECommentInputBackgroundView
- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideComment"]) {
		[self removeFromSuperview];
		return;
	}
}
%end

// 移除共创头像列表
%hook AWEPlayInteractionCoCreatorNewInfoView
- (void)layoutSubviews {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideGongChuang"]) {
		if ([self respondsToSelector:@selector(removeFromSuperview)]) {
			[self removeFromSuperview];
		}
		self.hidden = YES;
		return;
	}
	%orig;
}
%end

// 隐藏弹幕按钮
%hook AWEPlayDanmakuInputContainView

- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideDanmuButton"]) {
		self.hidden = YES;
	}
}

%end

// 隐藏作者店铺
%hook AWEECommerceEntryView

- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideHisShop"]) {
		UIView *parentView = self.superview;
		if (parentView) {
			parentView.hidden = YES;
		} else {
			self.hidden = YES;
		}
	}
}

%end

// 隐藏每日精选
%hook AWETemplateTagsCommonView
- (id)initWithFrame:(CGRect)frame {
    self = %orig;
    if ([NSUserDefaults.standardUserDefaults boolForKey:@"DYYYHideTemplateTags"]) {
        self.hidden = YES;
    }
    return self;
}
%end

// 隐藏挑战贴纸
%hook AWEFeedStickerContainerView

- (BOOL)isHidden {
	BOOL origHidden = %orig;
	BOOL hideRecommend = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideChallengeStickers"];
	return origHidden || hideRecommend;
}

- (void)setHidden:(BOOL)hidden {
	BOOL forceHide = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideChallengeStickers"];
	%orig(forceHide ? YES : hidden);
}

%end

	// 去除"我的"加入挑战横幅
%hook AWEPostWorkViewController
- (BOOL)isDouGuideTipViewShow {
	BOOL r = %orig;
	NSLog(@"Original value: %@", @(r));
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideChallengeStickers"]) {
		NSLog(@"Force return YES");
		return YES;
	}
	return r;
}
%end

// 隐藏拍同款
%hook AWEFeedAnchorContainerView

- (BOOL)isHidden {
	BOOL origHidden = %orig;
	BOOL hideSamestyle = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideFeedAnchorContainer"];
	return origHidden || hideSamestyle;
}

- (void)setHidden:(BOOL)hidden {
	BOOL forceHide = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideFeedAnchorContainer"];
	%orig(forceHide ? YES : hidden);
}

%end

// 隐藏合集和声明
%hook AWEAntiAddictedNoticeBarView
- (void)layoutSubviews {
	%orig;

	// 获取 tipsLabel 属性
	UILabel *tipsLabel = [self valueForKey:@"tipsLabel"];

	if (tipsLabel && [tipsLabel isKindOfClass:%c(UILabel)]) {
		NSString *labelText = tipsLabel.text;

		if (labelText) {
			// 明确判断是合集还是作者声明
			if ([labelText containsString:@"合集"]) {
				// 如果是合集，只检查合集的开关
				if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideTemplateVideo"]) {
					[self removeFromSuperview];
				}
			} else {
				// 如果不是合集（即作者声明），只检查声明的开关
				if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideAntiAddictedNotice"]) {
					[self removeFromSuperview];
				}
			}
		}
	}
}
%end

// 右侧按钮相关
%hook AWEFeedVideoButton

- (void)layoutSubviews {
	%orig;

	NSString *accessibilityLabel = self.accessibilityLabel;

	if ([accessibilityLabel isEqualToString:@"点赞"]) {
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideLikeButton"]) {
			[self removeFromSuperview];
			return;
		}
	} else if ([accessibilityLabel isEqualToString:@"评论"]) {
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCommentButton"]) {
			[self removeFromSuperview];
			return;
		}
	} else if ([accessibilityLabel isEqualToString:@"分享"]) {
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideShareButton"]) {
			[self removeFromSuperview];
			return;
		}
	} else if ([accessibilityLabel isEqualToString:@"收藏"]) {
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCollectButton"]) {
			[self removeFromSuperview];
			return;
		}
	}
}

%end

// 隐藏挑战贴纸
%hook ACCGestureResponsibleStickerView
- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideChallengeStickers"]) {
		[self removeFromSuperview];
		return;
	}
}
%end

// 隐藏音乐按钮
%hook AWEMusicCoverButton

- (void)layoutSubviews {
	%orig;

	NSString *accessibilityLabel = self.accessibilityLabel;

	if ([accessibilityLabel isEqualToString:@"音乐详情"]) {
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideMusicButton"]) {
			[self removeFromSuperview];
			return;
		}
	}
}

%end

%hook AWEPlayInteractionListenFeedView
- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideMusicButton"]) {
		[self removeFromSuperview];
		return;
	}
}
%end

// 移除头像按钮和加号
%hook AWEPlayInteractionFollowPromptView

- (void)layoutSubviews {
	%orig;

	NSString *accessibilityLabel = self.accessibilityLabel;

	if ([accessibilityLabel isEqualToString:@"关注"]) {
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideAvatarButton"]) {
			[self removeFromSuperview];
			return;
		}
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideFollowPromptView"]) {
			self.userInteractionEnabled = NO;
			[self removeFromSuperview];
			return; //移除头像加号
		}
	}
}

%end

// 底栏相关
%hook AWENormalModeTabBar

- (void)layoutSubviews {
	%orig;

	BOOL hideShop = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideShopButton"];
	BOOL hideMsg = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideMessageButton"];
	BOOL hideFri = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideFriendsButton"];
	BOOL hideMe = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideMyButton"];

	NSMutableArray *visibleButtons = [NSMutableArray array];
	Class generalButtonClass = %c(AWENormalModeTabBarGeneralButton);
	Class plusButtonClass = %c(AWENormalModeTabBarGeneralPlusButton);

	for (UIView *subview in self.subviews) {
		if (![subview isKindOfClass:generalButtonClass] && ![subview isKindOfClass:plusButtonClass])
			continue;

		NSString *label = subview.accessibilityLabel;
		BOOL shouldHide = NO;

		if ([label isEqualToString:@"商城"]) {
			shouldHide = hideShop;
		} else if ([label containsString:@"消息"]) {
			shouldHide = hideMsg;
		} else if ([label containsString:@"朋友"]) {
			shouldHide = hideFri;
		} else if ([label containsString:@"我"]) {
			shouldHide = hideMe;
		}

		if (!shouldHide) {
			[visibleButtons addObject:subview];
		} else {
			[subview removeFromSuperview];
		}
	}

	[visibleButtons sortUsingComparator:^NSComparisonResult(UIView *a, UIView *b) {
	  return [@(a.frame.origin.x) compare:@(b.frame.origin.x)];
	}];

	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		// iPad端布局逻辑
		UIView *targetView = nil;
		CGFloat containerWidth = self.bounds.size.width;
		CGFloat offsetX = 0;

		// 查找目标容器视图
		for (UIView *subview in self.subviews) {
			if ([subview class] == [UIView class] && fabs(subview.frame.size.width - self.bounds.size.width) > 0.1) {
				targetView = subview;
				containerWidth = subview.frame.size.width;
				offsetX = subview.frame.origin.x;
				break;
			}
		}

		// 在目标容器内均匀分布按钮
		CGFloat buttonWidth = containerWidth / visibleButtons.count;
		for (NSInteger i = 0; i < visibleButtons.count; i++) {
			UIView *button = visibleButtons[i];
			button.frame = CGRectMake(offsetX + (i * buttonWidth), button.frame.origin.y, buttonWidth, button.frame.size.height);
		}
	} else {
		// iPhone端布局逻辑
		CGFloat totalWidth = self.bounds.size.width;
		CGFloat buttonWidth = totalWidth / visibleButtons.count;

		for (NSInteger i = 0; i < visibleButtons.count; i++) {
			UIView *button = visibleButtons[i];
			button.frame = CGRectMake(i * buttonWidth, button.frame.origin.y, buttonWidth, button.frame.size.height);
		}
	}
}

%end

// 默认隐藏双指缩放横线
%hook AWELoadingAndVolumeView
	// 拦截初始化方法，阻止视图创建
- (instancetype)initWithFrame:(CGRect)frame {
    return nil;
}

%end

// 隐藏状态栏
%hook AWEFeedRootViewController
- (BOOL)prefersStatusBarHidden {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisHideStatusbar"]) {
		return YES;
	} else {
		if (class_getInstanceMethod([self class], @selector(prefersStatusBarHidden)) !=
		    class_getInstanceMethod([%c(AWEFeedRootViewController) class], @selector(prefersStatusBarHidden))) {
			return %orig;
		}
		return NO;
	}
}
%end

	// 直播状态栏
%hook IESLiveAudienceViewController
- (BOOL)prefersStatusBarHidden {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisHideStatusbar"]) {
		return YES;
	} else {
		if (class_getInstanceMethod([self class], @selector(prefersStatusBarHidden)) !=
		    class_getInstanceMethod([%c(IESLiveAudienceViewController) class], @selector(prefersStatusBarHidden))) {
			return %orig;
		}
		return NO;
	}
}
%end

	// 主页状态栏
%hook AWEAwemeDetailTableViewController
- (BOOL)prefersStatusBarHidden {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisHideStatusbar"]) {
		return YES;
	} else {
		if (class_getInstanceMethod([self class], @selector(prefersStatusBarHidden)) !=
		    class_getInstanceMethod([%c(AWEAwemeDetailTableViewController) class], @selector(prefersStatusBarHidden))) {
			return %orig;
		}
		return NO;
	}
}
%end

	// 图文状态栏
%hook AWEFullPageFeedNewContainerViewController
- (BOOL)prefersStatusBarHidden {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisHideStatusbar"]) {
		return YES;
	} else {
		if (class_getInstanceMethod([self class], @selector(prefersStatusBarHidden)) !=
		    class_getInstanceMethod([%c(AWEFullPageFeedNewContainerViewController) class], @selector(prefersStatusBarHidden))) {
			return %orig;
		}
		return NO;
	}
}
%end

// 隐藏视频定位
%hook AWEFeedTemplateAnchorView

- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideLocation"]) {
		[self removeFromSuperview];
		return;
	}
}

%end

// 隐藏相关搜索
%hook AWEPlayInteractionSearchAnchorView

- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideInteractionSearch"]) {
		[self removeFromSuperview];
		return;
	}
}

%end

// 隐藏去汽水听
%hook AWEAwemeMusicInfoView

- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideQuqishuiting"]) {
		UIView *parentView = self.superview;
		if (parentView) {
			parentView.hidden = YES;
		} else {
			self.hidden = YES;
		}
	}
}

%end

// 隐藏短剧合集
%hook AWETemplatePlayletView

- (void)layoutSubviews {

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideTemplatePlaylet"]) {
		if ([self respondsToSelector:@selector(removeFromSuperview)]) {
			[self removeFromSuperview];
		}
		self.hidden = YES;
		return;
	}
	%orig;
}
%end

// 隐藏作者作品内搜索框
%hook AWESearchEntranceView

- (void)layoutSubviews {

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideSearchEntrance"]) {
		self.hidden = YES;
		return;
	}
	%orig;
}

%end

// 隐藏好友分享私信
%hook AFDNewFastReplyView

- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePrivateMessages"]) {
		UIView *parentView = self.superview;
		if (parentView) {
			parentView.hidden = YES;
		} else {
			self.hidden = YES;
		}
	}
}

%end

// 隐藏热点热搜
%hook AWETemplateHotspotView

- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideHotspot"]) {
		[self removeFromSuperview];
		return;
	}
}

%end

// 隐藏直播点歌
%hook IESLiveKTVSongIndicatorView
- (void)layoutSubviews {
	%orig;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideKTVSongIndicator"]) {
		self.hidden = YES;
		[self removeFromSuperview];
	}
}
%end

// 隐藏顶栏关注下的提示线
%hook AWEFeedMultiTabSelectedContainerView

- (void)setHidden:(BOOL)hidden {
	BOOL forceHide = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidentopbarprompt"];

	if (forceHide) {
		%orig(YES);
	} else {
		%orig(hidden);
	}
}

%end

// 隐藏点击推荐
%hook AFDRecommendToFriendEntranceLabel
- (void)layoutSubviews {
	%orig;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideRecommendTips"]) {
		UIView *parentView = self.superview;
		if (parentView) {
			parentView.hidden = YES;
		} else {
			self.hidden = YES;
		}
	}
}

%end

// 禁用双击视频点赞
%hook AWEPlayInteractionViewController

- (void)onVideoPlayerViewDoubleClicked:(id)arg1 {
	BOOL isSwitchOn = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYDouble"];
	if (!isSwitchOn) {
		%orig;
	}
}
%end

// 隐藏相机定位
%hook AWETemplateCommonView
- (void)layoutSubviews {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCameraLocation"]) {
		if ([self respondsToSelector:@selector(removeFromSuperview)]) {
			[self removeFromSuperview];
		}
		self.hidden = YES;
		return;
	}
	%orig;
}
%end

// 隐藏礼物展馆
%hook BDXWebView
- (void)layoutSubviews {
	%orig;

	BOOL enabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideGiftPavilion"];
	if (!enabled)
		return;

	NSString *title = [self valueForKey:@"title"];

	if ([title containsString:@"任务Banner"] || [title containsString:@"活动Banner"]) {
		[self removeFromSuperview];
	}
}
%end

// 隐藏礼物展馆
%hook IESLiveActivityBannnerView
- (void)layoutSubviews {
	%orig;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideGiftPavilion"]) {
		self.hidden = YES;
	}
}

%end

// 隐藏直播广场
%hook IESLiveFeedDrawerEntranceView
- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideLivePlayground"]) {
		self.hidden = YES;
	}
}

%end

// 隐藏直播退出清屏按钮
%hook IESLiveButton
- (void)layoutSubviews {
	%orig;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideLiveRoomClear"]) {
		if ([self.accessibilityLabel isEqualToString:@"退出清屏"] && self.superview) {
			[self.superview removeFromSuperview];
		}
	}
}

%end

// 隐藏直播间关闭按钮
%hook IESLiveLayoutPlaceholderView
- (void)layoutSubviews {
	%orig;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideLiveRoomClose"]) {
		self.hidden = YES;
	}
}
%end

// 隐藏直播间商品信息
%hook IESECLivePluginLayoutView
- (void)layoutSubviews {
	%orig;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideLiveGoodsMsg"]) {
		[self removeFromSuperview];
	}
}
%end

// 隐藏直播间点赞动画
%hook HTSLiveDiggView
- (void)setIconImageView:(UIImageView *)arg1 {
	if (DYYYGetBool(@"DYYYHideLiveLikeAnimation")) {
		%orig(nil);
	} else {
		%orig(arg1);
	}
}
%end

// 隐藏双列箭头
%hook AWENormalModeTabBarFeedView
- (void)layoutSubviews {
	%orig;

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideDoubleColumnEntry"]) {
		for (UIView *subview in self.subviews) {
			if (![subview isKindOfClass:[UILabel class]]) {
				subview.hidden = YES;
			}
		}
	}
}
%end

// 注意保留
%ctor {
	%init(DYYYSettingsGesture);
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYUserAgreementAccepted"]) {
		%init;
		BOOL isAutoPlayEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableAutoPlay"];
		if (isAutoPlayEnabled) {
			%init(AutoPlay);
		}
	}
}
