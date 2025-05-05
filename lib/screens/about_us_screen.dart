import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:tiklarm/services/theme_service.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  // Helper function to launch URLs
  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  // Helper function specifically for social media with multiple fallbacks
  Future<void> _launchSocialMedia(
    BuildContext context,
    String url,
    String username,
    String platform,
  ) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Try alternative URL formats
        String altUrl;
        switch (platform) {
          case 'twitter':
            altUrl = 'https://x.com/$username';
            break;
          case 'instagram':
            altUrl = 'instagram://user?username=$username';
            break;
          case 'github':
            altUrl = 'https://github.com/$username';
            break;
          case 'snapchat':
            altUrl = 'https://www.snapchat.com/add/$username';
            break;
          case 'threads':
            altUrl = 'https://www.threads.net/@$username';
            break;
          default:
            altUrl = url;
        }

        final Uri altUri = Uri.parse(altUrl);
        if (await canLaunchUrl(altUri)) {
          await launchUrl(altUri, mode: LaunchMode.externalApplication);
        } else {
          // Show error message
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Could not open $platform. Check if you have the app installed.',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Helper function for launching email
  Future<void> _launchEmail(BuildContext context, String email) async {
    final emailLaunchUri = Uri(scheme: 'mailto', path: email);

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        // Try alternative approach
        final String mailtoUrl = 'mailto:$email';
        final Uri mailtoUri = Uri.parse(mailtoUrl);

        if (await canLaunchUrl(mailtoUri)) {
          await launchUrl(mailtoUri);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Could not open email client for $email'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening email: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDarkMode = Provider.of<ThemeService>(context).isDarkMode;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('About Us'),
        backgroundColor: primaryColor,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 2,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Get screen dimensions for responsive sizing
          final mediaQuery = MediaQuery.of(context);
          final screenWidth = mediaQuery.size.width;
          final screenHeight = mediaQuery.size.height;

          // Determine screen size categories
          final bool isSmallScreen = screenWidth < 360;
          final bool isLandscape =
              mediaQuery.orientation == Orientation.landscape;

          // Calculate responsive sizing
          final double horizontalPadding = screenWidth * 0.05;
          final double verticalPadding = screenHeight * 0.02;

          // Calculate adaptive sizes based on screen dimensions
          final double headerLogoSize = constraints.maxWidth * 0.25;
          final double headerIconSize = headerLogoSize * 0.6;
          final double headerTitleSize = constraints.maxWidth * 0.06;
          final double headerSubtitleSize = constraints.maxWidth * 0.04;

          final double sectionTitleSize = constraints.maxWidth * 0.05;
          final double avatarRadius = constraints.maxWidth * 0.1;
          final double avatarFontSize = avatarRadius * 0.6;

          final double nameFontSize = constraints.maxWidth * 0.045;
          final double subtitleFontSize = constraints.maxWidth * 0.035;
          final double bodyTextSize = constraints.maxWidth * 0.033;
          final double iconSize = constraints.maxWidth * 0.035;

          // Create adaptive layout for different orientations
          Widget headerContent = Column(
            children: [
              Container(
                height: headerLogoSize,
                width: headerLogoSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 1,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Padding(
                      padding: EdgeInsets.all(headerLogoSize * 0.1),
                      child: Icon(
                        Icons.alarm,
                        size: headerIconSize,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: verticalPadding),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Tiklarm',
                  style: TextStyle(
                    fontSize: headerTitleSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: verticalPadding * 0.4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: headerSubtitleSize,
                  ),
                ),
              ),
            ],
          );

          if (isLandscape) {
            headerContent = Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  height: headerLogoSize * 0.8,
                  width: headerLogoSize * 0.8,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 1,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Padding(
                        padding: EdgeInsets.all(headerLogoSize * 0.08),
                        child: Icon(
                          Icons.alarm,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: horizontalPadding),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Tiklarm',
                        style: TextStyle(
                          fontSize: headerTitleSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: verticalPadding * 0.2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Version 1.0.0',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: headerSubtitleSize,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // App Logo and Name
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(screenWidth * 0.06),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    boxShadow: [
                      BoxShadow(
                        color: isDarkMode
                            ? Colors.black.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: headerContent,
                ),

                SizedBox(height: verticalPadding * 1.2),

                // Developer Information
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Developer',
                          style: TextStyle(
                            fontSize: sectionTitleSize,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onBackground,
                          ),
                        ),
                      ),
                      SizedBox(height: verticalPadding * 0.8),

                      // Developer Card
                      Container(
                        padding: EdgeInsets.all(screenWidth * 0.05),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: isDarkMode
                                  ? Colors.black.withOpacity(0.2)
                                  : Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Developer Profile
                            LayoutBuilder(
                              builder: (context, innerConstraints) {
                                return Row(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: primaryColor.withOpacity(0.2),
                                            spreadRadius: 1,
                                            blurRadius: 5,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        radius: avatarRadius,
                                        backgroundColor: primaryColor,
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Padding(
                                            padding: EdgeInsets.all(
                                              avatarRadius * 0.3,
                                            ),
                                            child: Text(
                                              'HT',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: avatarFontSize,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: horizontalPadding * 0.8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              'Haseeb Tariq',
                                              style: TextStyle(
                                                fontSize: nameFontSize,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context).colorScheme.onSurface,
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            height: verticalPadding * 0.2,
                                          ),
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              'Mobile App Developer',
                                              style: TextStyle(
                                                fontSize: subtitleFontSize,
                                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            height: verticalPadding * 0.4,
                                          ),
                                          InkWell(
                                            onTap: () async {
                                              await _launchEmail(
                                                context,
                                                'haseebawang4545@gmail.com',
                                              );
                                            },
                                            borderRadius: BorderRadius.circular(30),
                                            child: SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              physics: const BouncingScrollPhysics(),
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: horizontalPadding * 0.5,
                                                  vertical: 8,
                                                ),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: [
                                                      primaryColor.withOpacity(0.8),
                                                      primaryColor.withOpacity(0.6),
                                                    ],
                                                  ),
                                                  borderRadius: BorderRadius.circular(30),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: primaryColor.withOpacity(0.3),
                                                      blurRadius: 8,
                                                      spreadRadius: 1,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.all(6),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white.withOpacity(0.2),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: Icon(
                                                        Icons.email_outlined,
                                                        size: iconSize,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    SizedBox(width: horizontalPadding * 0.3),
                                                    Text(
                                                      'haseebawang4545@gmail.com',
                                                      style: TextStyle(
                                                        fontSize: subtitleFontSize * 0.85,
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.w500,
                                                        letterSpacing: 0.2,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),

                            SizedBox(height: verticalPadding * 1.2),
                            const Divider(),
                            SizedBox(height: verticalPadding * 0.8),

                            // Social Media Links
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Connect with me',
                                style: TextStyle(
                                  fontSize: subtitleFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                            SizedBox(height: verticalPadding * 0.8),

                            // Social Links Grid
                            GridView.count(
                              crossAxisCount: isLandscape ? 5 : 3,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              childAspectRatio: isSmallScreen ? 1.1 : 1.3,
                              mainAxisSpacing: screenWidth * 0.03,
                              crossAxisSpacing: screenWidth * 0.03,
                              children: [
                                _buildSocialButton(
                                  context: context,
                                  title: 'Instagram',
                                  icon: Icons.photo_camera,
                                  color: const Color(0xFFE1306C),
                                  onTap: () => _launchSocialMedia(
                                    context,
                                    'https://instagram.com/haseeb_awan45',
                                    'haseeb_awan45',
                                    'instagram',
                                  ),
                                  constraints: constraints,
                                ),
                                _buildSocialButton(
                                  context: context,
                                  title: 'Twitter',
                                  icon: Icons.alternate_email,
                                  color: const Color(0xFF1DA1F2),
                                  onTap: () => _launchSocialMedia(
                                    context,
                                    'https://twitter.com/haseeb_awan45',
                                    'haseeb_awan45',
                                    'twitter',
                                  ),
                                  constraints: constraints,
                                ),
                                _buildSocialButton(
                                  context: context,
                                  title: 'GitHub',
                                  icon: Icons.code,
                                  color: const Color(0xFF333333),
                                  onTap: () => _launchSocialMedia(
                                    context,
                                    'https://github.com/HaseebTariq45',
                                    'HaseebTariq45',
                                    'github',
                                  ),
                                  constraints: constraints,
                                ),
                                _buildSocialButton(
                                  context: context,
                                  title: 'Snapchat',
                                  icon: Icons.whatshot,
                                  color: const Color(0xFFFFFC00),
                                  textColor: Colors.black,
                                  onTap: () => _launchSocialMedia(
                                    context,
                                    'https://snapchat.com/add/haseeb_awan45',
                                    'haseeb_awan45',
                                    'snapchat',
                                  ),
                                  constraints: constraints,
                                ),
                                _buildSocialButton(
                                  context: context,
                                  title: 'Threads',
                                  icon: Icons.stream,
                                  color: const Color(0xFF000000),
                                  onTap: () => _launchSocialMedia(
                                    context,
                                    'https://threads.net/@haseeb_awan45',
                                    'haseeb_awan45',
                                    'threads',
                                  ),
                                  constraints: constraints,
                                ),
                              ],
                            ),

                            SizedBox(height: verticalPadding * 1.2),
                            const Divider(),
                            SizedBox(height: verticalPadding * 0.8),

                            // GitHub Project
                            InkWell(
                              onTap: () => _launchSocialMedia(
                                context,
                                'https://github.com/HaseebTariq45',
                                'HaseebTariq45',
                                'github',
                              ),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: Container(
                                  padding: EdgeInsets.all(screenWidth * 0.04),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        const Color(0xFF333333),
                                        const Color(0xFF222222),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(
                                          screenWidth * 0.025,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.3),
                                            width: 2,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.code,
                                          color: Colors.white,
                                          size: iconSize * 1.2,
                                        ),
                                      ),
                                      SizedBox(width: horizontalPadding * 0.5),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'View Project on GitHub',
                                            style: TextStyle(
                                              fontSize: subtitleFontSize,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              letterSpacing: 0.5,
                                              height: 1.0,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black.withOpacity(0.5),
                                                  blurRadius: 2,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                            height: verticalPadding * 0.2,
                                          ),
                                          Text(
                                            '@HaseebTariq45',
                                            style: TextStyle(
                                              fontSize: subtitleFontSize * 0.8,
                                              color: Colors.white.withOpacity(0.7),
                                              letterSpacing: 0.3,
                                              height: 1.0,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(width: horizontalPadding * 0.5),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        padding: EdgeInsets.all(screenWidth * 0.02),
                                        child: Icon(
                                          Icons.arrow_forward,
                                          size: iconSize,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: verticalPadding * 1.2),

                      // App Information
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'About This App',
                          style: TextStyle(
                            fontSize: sectionTitleSize,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onBackground,
                          ),
                        ),
                      ),
                      SizedBox(height: verticalPadding * 0.8),
                      Container(
                        padding: EdgeInsets.all(screenWidth * 0.05),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: isDarkMode
                                  ? Colors.black.withOpacity(0.2)
                                  : Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Tiklarm',
                                style: TextStyle(
                                  fontSize: subtitleFontSize + 2,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                            SizedBox(height: verticalPadding * 0.6),
                            Text(
                              'Tiklarm is a comprehensive alarm, timer, and stopwatch application designed to enhance your productivity and time management. With an elegant and intuitive interface, it offers all the timing tools you need in one place.',
                              style: TextStyle(
                                fontSize: bodyTextSize,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                height: 1.5,
                              ),
                            ),
                            SizedBox(height: verticalPadding * 0.8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Features:',
                                style: TextStyle(
                                  fontSize: subtitleFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                            SizedBox(height: verticalPadding * 0.4),
                            _FeatureItem(
                              text: 'Modern beautiful alarm clock with customizable settings',
                              iconSize: iconSize,
                              fontSize: bodyTextSize,
                              successColor: primaryColor,
                            ),
                            _FeatureItem(
                              text: 'Elegant countdown timer with animations',
                              iconSize: iconSize,
                              fontSize: bodyTextSize,
                              successColor: primaryColor,
                            ),
                            _FeatureItem(
                              text: 'Precise stopwatch with lap timing capabilities',
                              iconSize: iconSize,
                              fontSize: bodyTextSize,
                              successColor: primaryColor,
                            ),
                            _FeatureItem(
                              text: 'World clock for tracking time in multiple locations',
                              iconSize: iconSize,
                              fontSize: bodyTextSize,
                              successColor: primaryColor,
                            ),
                            _FeatureItem(
                              text: 'Customizable alarm sounds and vibration options',
                              iconSize: iconSize,
                              fontSize: bodyTextSize,
                              successColor: primaryColor,
                            ),
                            _FeatureItem(
                              text: 'Dark mode and light mode support',
                              iconSize: iconSize,
                              fontSize: bodyTextSize,
                              successColor: primaryColor,
                            ),
                            _FeatureItem(
                              text: 'Intuitive and beautiful user interface',
                              iconSize: iconSize,
                              fontSize: bodyTextSize,
                              successColor: primaryColor,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: verticalPadding * 2),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSocialButton({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    Color? textColor,
    required VoidCallback onTap,
    required BoxConstraints constraints,
  }) {
    final double iconSize = constraints.maxWidth * 0.05;
    final double fontSize = constraints.maxWidth * 0.028;
    final isDarkMode = Provider.of<ThemeService>(context).isDarkMode;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: constraints.maxWidth * 0.01,
          vertical: constraints.maxWidth * 0.02,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.7),
              color.withOpacity(0.4),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon, 
              color: Colors.white,
              size: iconSize * 1.2,
            ),
            SizedBox(height: constraints.maxHeight * 0.01),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                  height: 1.0,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final String text;
  final double iconSize;
  final double fontSize;
  final Color successColor;

  const _FeatureItem({
    required this.text,
    this.iconSize = 16,
    this.fontSize = 14,
    this.successColor = Colors.green,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).size.height * 0.01,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            color: successColor,
            size: iconSize,
          ),
          SizedBox(width: MediaQuery.of(context).size.width * 0.02),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 