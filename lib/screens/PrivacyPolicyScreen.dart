import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../core/constant/app_colors.dart';
import '../core/constant/styles/app_text_style.dart';
import '../utils/Extensions/app_common.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  @override
  PrivacyPolicyScreenState createState() => PrivacyPolicyScreenState();
}

class PrivacyPolicyScreenState extends State<PrivacyPolicyScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          // Modern App Bar with gradient background
          _buildModernAppBar(),

          // Content
          Expanded(
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: AnimationLimiter(
                      child: ListView(
                        padding: EdgeInsets.all(0),
                        children: AnimationConfiguration.toStaggeredList(
                          duration: Duration(milliseconds: 600),
                          childAnimationBuilder: (widget) => SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(child: widget),
                          ),
                          children: [
                            SizedBox(height: 24),
                            _buildHeaderCard(),
                            _buildSectionCard(
                              icon: MaterialCommunityIcons.information_outline,
                              title: '1. المعلومات التي نجمعها',
                              content:
                                  'عند استخدامك لتطبيق مسارك، قد نقوم بجمع المعلومات التالية:',
                              items: [
                                'الاسم الكامل',
                                'رقم الهاتف',
                                'البريد الإلكتروني',
                                'الموقع الجغرافي (GPS) أثناء استخدام التطبيق لتحديد موقعك وتوجيه السائقين أو الركاب.',
                              ],
                            ),
                            _buildSectionCard(
                              icon: MaterialCommunityIcons.cog_outline,
                              title: '2. كيفية استخدام المعلومات',
                              content: 'نستخدم المعلومات التي نجمعها من أجل:',
                              items: [
                                'إنشاء الحساب وتفعيل الخدمة.',
                                'تحسين جودة الخدمة وتوفير تجربة مخصصة.',
                                'التواصل معك بشأن الرحلات أو العروض أو الدعم الفني.',
                                'التحقق من الهوية وضمان سلامة المستخدمين.',
                                'إرسال إشعارات فورية تتعلق بالرحلة أو حالة الطلب.',
                              ],
                            ),
                            _buildSectionCard(
                              icon: MaterialCommunityIcons.share_outline,
                              title: '3. مشاركة المعلومات',
                              content:
                                  'قد نشارك بياناتك مع أطراف ثالثة في الحالات التالية فقط:',
                              items: [
                                'مع السائقين أو الركاب الآخرين في إطار الرحلات.',
                                'مع مزودي الخدمات (مثل شركات الدفع أو الدعم الفني) تحت اتفاقيات حماية بيانات.',
                                'إذا طلب القانون ذلك، أو لحماية حقوق التطبيق أو المستخدمين.',
                              ],
                            ),
                            _buildSectionCard(
                              icon: MaterialCommunityIcons.shield_check_outline,
                              title: '4. تخزين البيانات وحمايتها',
                              content:
                                  'نُخزن بياناتك على خوادم آمنة ونتخذ الإجراءات الفنية والتنظيمية المناسبة لحمايتها من الوصول غير المصرح به أو التعديل أو الحذف.',
                              items: [],
                            ),
                            _buildSectionCard(
                              icon:
                                  MaterialCommunityIcons.account_check_outline,
                              title: '5. حقوق المستخدم',
                              content: 'لديك الحق في:',
                              items: [
                                'طلب الوصول إلى معلوماتك.',
                                'تعديل أو حذف بياناتك.',
                                'سحب الموافقة في أي وقت (قد يؤثر ذلك على استخدام التطبيق).',
                              ],
                            ),
                            _buildContactCard(),
                            SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernAppBar() {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.darkPrimary,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Text(
                'سياسة الخصوصية',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      offset: Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              Spacer(),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      margin: EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              MaterialCommunityIcons.shield_check,
              color: Colors.white,
              size: 28,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'سياسة الخصوصية – تطبيق مسارك',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textColor,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'آخر تحديث: 25 يونيو 2025',
              style: AppTextStyles.sMedium14(color: AppColors.primary),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'نحن في مسارك نحترم خصوصيتك وملتزمون بحماية بياناتك الشخصية. توضح هذه السياسة كيف نجمع، نستخدم، ونشارك معلوماتك عند استخدامك لتطبيقنا.',
            style: AppTextStyles.sRegular14(color: AppColors.textColor),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String content,
    required List<String> items,
  }) {
    return Container(
      margin: EdgeInsets.fromLTRB(20, 0, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style:
                        AppTextStyles.sSemiBold16(color: AppColors.textColor),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (content.isNotEmpty) ...[
                  Text(
                    content,
                    style: AppTextStyles.sRegular14(color: AppColors.textColor),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                  if (items.isNotEmpty) SizedBox(height: 16),
                ],

                // Items
                ...items.map((item) => _buildBulletItem(item)).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletItem(String text) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: TextDirection.rtl,
        children: [
          Container(
            margin: EdgeInsets.only(top: 8, left: 12),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.sRegular14(color: AppColors.textColor),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      margin: EdgeInsets.fromLTRB(20, 8, 20, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.darkPrimary,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    MaterialCommunityIcons.phone_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    '6. بيانات الاتصال',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'إذا كان لديك أي استفسارات بخصوص سياسة الخصوصية، يمكنك التواصل معنا عبر:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
            SizedBox(height: 20),

            // Contact Items
            _buildContactItem(
              icon: MaterialCommunityIcons.email_outline,
              label: 'البريد الإلكتروني',
              value: 'elreefyahmed257@gmail.com',
            ),
            SizedBox(height: 12),
            _buildContactItem(
              icon: MaterialCommunityIcons.phone_outline,
              label: 'الهاتف',
              value: '+201097051812',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  textDirection: TextDirection.ltr,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
