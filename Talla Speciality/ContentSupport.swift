import Foundation
import SwiftUI
#if canImport(UserNotifications)
import UserNotifications
#endif
#if canImport(PassKit)
import PassKit
#endif
#if canImport(SafariServices) && canImport(UIKit)
import SafariServices
import UIKit
#endif

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english
    case arabic

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system:
            return "System"
        case .english:
            return "English"
        case .arabic:
            return "العربية"
        }
    }

    var localeIdentifier: String {
        switch self {
        case .system:
            return Locale.current.identifier
        case .english:
            return "en"
        case .arabic:
            return "ar"
        }
    }

    var layoutDirection: LayoutDirection {
        switch effectiveLanguageCode {
        case "ar":
            return .rightToLeft
        default:
            return .leftToRight
        }
    }

    var effectiveLanguageCode: String {
        switch self {
        case .system:
            return Locale.current.language.languageCode?.identifier ?? "en"
        case .english:
            return "en"
        case .arabic:
            return "ar"
        }
    }
}

enum AppLocalization {
    private static let translations: [String: [String: String]] = [
        "language": ["ar": "اللغة"],
        "home": ["ar": "الرئيسية"],
        "shop": ["ar": "المتجر"],
        "brewing": ["ar": "التحضير"],
        "account": ["ar": "الحساب"],
        "appearance": ["ar": "المظهر"],
        "explore": ["ar": "استكشف"],
        "all_products": ["ar": "كل المنتجات"],
        "browse_catalog": ["ar": "تصفح حسب الفئة، واكتشف مفضلات العملاء، وأضف إلى السلة بسهولة."],
        "categories": ["ar": "الفئات"],
        "clear": ["ar": "مسح"],
        "show_everything": ["ar": "عرض الكل"],
        "loading_shop": ["ar": "جاري تحميل المتجر"],
        "no_products": ["ar": "لا توجد منتجات مطابقة لهذه الفئة حالياً."],
        "show_all_products": ["ar": "عرض كل المنتجات"],
        "retry": ["ar": "إعادة المحاولة"],
        "account_title": ["ar": "الحساب"],
        "customer_sign_in": ["ar": "تسجيل دخول العملاء"],
        "account_create_copy": ["ar": "أنشئ حساباً واحداً للطلب والمكافآت والبيانات المحفوظة."],
        "account_change_password_copy": ["ar": "غيّر كلمة المرور بدون الحاجة إلى استعادة جلسة تسجيل الدخول أولاً."],
        "account_sign_in_copy": ["ar": "سجّل الدخول مرة واحدة للوصول إلى المكافآت والعناوين المحفوظة وسجل الطلبات."],
        "sign_in": ["ar": "تسجيل الدخول"],
        "create_account": ["ar": "إنشاء حساب"],
        "change_password": ["ar": "تغيير كلمة المرور"],
        "first_name": ["ar": "الاسم الأول"],
        "last_name": ["ar": "اسم العائلة"],
        "email_address": ["ar": "البريد الإلكتروني"],
        "password": ["ar": "كلمة المرور"],
        "current_password": ["ar": "كلمة المرور الحالية"],
        "new_password": ["ar": "كلمة المرور الجديدة"],
        "confirm_password": ["ar": "تأكيد كلمة المرور"],
        "or_continue_with": ["ar": "أو تابع عبر"],
        "signing_in_with_apple": ["ar": "جارٍ تسجيل الدخول عبر Apple..."],
        "fast_access_checkout": ["ar": "وصول سريع للطلب والمكافآت"],
        "email_reset_link": ["ar": "إرسال رابط إعادة التعيين"],
        "sending_link": ["ar": "جارٍ إرسال الرابط..."],
        "already_have_account": ["ar": "لديك حساب بالفعل؟"],
        "back_to_sign_in": ["ar": "العودة لتسجيل الدخول"],
        "profile": ["ar": "الملف الشخصي"],
        "saved": ["ar": "محفوظ"],
        "save": ["ar": "حفظ"],
        "saving": ["ar": "جارٍ الحفظ..."],
        "save_profile": ["ar": "حفظ الملف الشخصي"],
        "confirm_new": ["ar": "تأكيد الجديدة"],
        "updating": ["ar": "جارٍ التحديث..."],
        "update_password": ["ar": "تحديث كلمة المرور"],
        "creating_account": ["ar": "جارٍ إنشاء الحساب..."],
        "updating_password": ["ar": "جارٍ تحديث كلمة المرور..."],
        "signing_in": ["ar": "جارٍ تسجيل الدخول..."],
        "watching": ["ar": "قيد المتابعة"],
        "watch": ["ar": "متابعة"],
        "view_details": ["ar": "عرض التفاصيل"],
        "choose_options": ["ar": "اختر الخيارات"],
        "add_to_bag": ["ar": "أضف إلى السلة"],
        "sold_out": ["ar": "نفد"],
        "default_variant": ["ar": "الافتراضي:"],
        "variants": ["ar": "الخيارات"],
        "available": ["ar": "متوفر"],
        "availability": ["ar": "التوفر"],
        "ready_to_order": ["ar": "جاهز للطلب الآن"],
        "currently_sold_out": ["ar": "غير متوفر حالياً"],
        "category": ["ar": "الفئة"]
        ,"customer": ["ar": "العميل"]
        ,"account_heading": ["ar": "الحساب"]
        ,"account_intro": ["ar": "أدر تسجيل دخولك، وراجع المكافآت، واحتفظ بعضويتك في مكان واحد."]
        ,"account_sync_hint": ["ar": "استخدم نفس البريد في الطلب والمكافآت حتى يبقى كل شيء متزامناً."]
        ,"library_delivery": ["ar": "المكتبة والتوصيل"]
        ,"library_delivery_subtitle": ["ar": "العناوين والتنبيهات والسلال المحفوظة لإعادة الطلب بسرعة."]
        ,"shopping_discovery": ["ar": "التسوق والاكتشاف"]
        ,"shopping_discovery_subtitle": ["ar": "المفضلة والعناصر التي شاهدتها والتوصيات."]
        ,"brewing_archive": ["ar": "أرشيف التحضير"]
        ,"brewing_archive_subtitle": ["ar": "احتفظ بوصفاتك المحفوظة قريباً منك."]
        ,"support_tools": ["ar": "الدعم وأدوات الحساب"]
        ,"support_tools_subtitle": ["ar": "مراجع سريعة وروابط مساعدة عند الحاجة."]
        ,"open_rewards": ["ar": "افتح المكافآت"]
        ,"open_rewards_detail": ["ar": "راجع الرصيد واستبدل المكافآت المتاحة."]
        ,"delivery_setup": ["ar": "إعداد التوصيل"]
        ,"delivery_setup_empty": ["ar": "أضف عنوانك الأول."]
        ,"address_saved_singular": ["ar": "تم حفظ عنوان واحد."]
        ,"address_saved_plural": ["ar": "تم حفظ %d عناوين."]
        ,"saved_picks": ["ar": "اختياراتك المحفوظة"]
        ,"saved_picks_empty": ["ar": "ابدأ ببناء قائمتك المفضلة."]
        ,"favorite_saved_singular": ["ar": "تم حفظ مفضل واحد."]
        ,"favorite_saved_plural": ["ar": "تم حفظ %d مفضلات."]
        ,"brew_archive": ["ar": "أرشيف التحضير"]
        ,"brew_archive_empty": ["ar": "احتفظ بالوصفات لوقت لاحق."]
        ,"recipe_saved_singular": ["ar": "تم حفظ وصفة واحدة."]
        ,"recipe_saved_plural": ["ar": "تم حفظ %d وصفات."]
        ,"loyalty": ["ar": "المكافآت"]
        ,"reserve_copy": ["ar": "استخدم بريد طلبك لفتح Beans والمكافآت ومزايا Reserve في مكان واحد."]
        ,"signed_in": ["ar": "تم تسجيل الدخول"]
        ,"beans_available": ["ar": "Beans المتاحة"]
        ,"next_reward": ["ar": "المكافأة التالية"]
        ,"tier_progress": ["ar": "تقدم المستوى"]
        ,"beans_to_go": ["ar": "متبقي %d Beans"]
        ,"beans_to_tier": ["ar": "متبقي %d Beans للوصول إلى %@"]
        ,"beans_count": ["ar": "%d Beans"]
        ,"beans_until_reward_unlock": ["ar": "متبقي %d Beans لفتح مكافأتك التالية."]
        ,"member_id": ["ar": "رقم العضوية"]
        ,"reserve_benefit": ["ar": "ميزة Reserve"]
        ,"lookup_rewards": ["ar": "عرض المكافآت"]
        ,"checking": ["ar": "جارٍ التحقق..."]
        ,"check_rewards": ["ar": "عرض المكافآت"]
        ,"sign_out": ["ar": "تسجيل الخروج"]
        ,"orders_award_beans": ["ar": "الطلبات المكتملة تمنح الآن 5 Beans لكل 1 دينار بحريني."]
        ,"earn_beans": ["ar": "اكسب Beans"]
        ,"earn_beans_rate": ["ar": "الطلبات المكتملة تمنح 5 Beans لكل 1 دينار بحريني يتم إنفاقه."]
        ,"earn_beans_detail": ["ar": "تتحدّث مكافآتك تلقائياً بعد تسجيل المشتريات المكتملة."]
        ,"redeem_rewards": ["ar": "استبدال المكافآت"]
        ,"reward_espresso_pour": ["ar": "إسبريسو صغير"]
        ,"reward_pastry_pairing": ["ar": "مرافقة معجنات"]
        ,"reward_signature_sip": ["ar": "مشروب مميز"]
        ,"reward_bag_credit": ["ar": "رصيد كيس قهوة"]
        ,"reward_talla_box_treat": ["ar": "هدية صندوق Talla"]
        ,"reward_gold_reserve_gift": ["ar": "هدية Gold Reserve"]
        ,"choose_reward_redeem": ["ar": "اختر مكافأة لاستبدالها باستخدام Beans المتاحة."]
        ,"reach_first_reward": ["ar": "اجمع 50 Beans لفتح أول مكافأة."]
        ,"expiring_rewards": ["ar": "المكافآت القريبة من الانتهاء"]
        ,"expiring_rewards_empty": ["ar": "ستظهر المكافآت المستبدلة هنا مع مدة صلاحيتها."]
        ,"expires_soon": ["ar": "ينتهي قريباً"]
        ,"recent_activity": ["ar": "النشاط الأخير"]
        ,"no_loyalty_activity": ["ar": "لا يوجد نشاط مكافآت بعد."]
        ,"voucher": ["ar": "القسيمة"]
        ,"multi_use": ["ar": "متعدد الاستخدام"]
        ,"single_use": ["ar": "استخدام واحد"]
        ,"expires": ["ar": "ينتهي"]
        ,"the_craft": ["ar": "الحرفة"]
        ,"brewing_methods": ["ar": "طرق التحضير"]
        ,"brewing_intro": ["ar": "أدلة لتحضير قهوة أفضل في المنزل."]
        ,"golden_ratio": ["ar": "النسبة الذهبية"]
        ,"strong_bold": ["ar": "قوي ومركز"]
        ,"balanced": ["ar": "متوازن"]
        ,"light_bright": ["ar": "خفيف ومشرق"]
        ,"ratio_copy": ["ar": "نسبة القهوة إلى الماء. عدّلها حسب ذوقك بناءً على التحميص وطريقة التحضير."]
        ,"coffee_journal": ["ar": "مجلة القهوة"]
        ,"source": ["ar": "المصدر"]
        ,"guide": ["ar": "الدليل"]
        ,"in_app_guide": ["ar": "دليل داخل التطبيق"]
        ,"coffee_journal_article": ["ar": "مقال من مجلة القهوة"]
        ,"use_built_in_guide": ["ar": "استخدم الدليل المدمج أدناه."]
        ,"open_full_guide": ["ar": "افتح دليل التحضير الكامل."]
        ,"open_guide": ["ar": "افتح الدليل"]
        ,"in_app": ["ar": "داخل التطبيق"]
        ,"ratio_calculator": ["ar": "حاسبة النسبة"]
        ,"coffee_grams": ["ar": "القهوة (غرام)"]
        ,"ratio": ["ar": "النسبة"]
        ,"water": ["ar": "ماء"]
        ,"ratio_based_on": ["ar": "بناءً على %@ غرام من القهوة بنسبة 1:%@."]
        ,"recipe_name": ["ar": "اسم الوصفة"]
        ,"save_recipe": ["ar": "حفظ الوصفة"]
        ,"active": ["ar": "نشط"]
        ,"customer_email": ["ar": "بريد العميل"]
        ,"rewards_sync": ["ar": "مزامنة المكافآت"]
        ,"rewards_sync_detail": ["ar": "ربطنا عرض المكافآت بهذا الحساب الآن."]
        ,"saved_addresses": ["ar": "العناوين المحفوظة"]
        ,"saved_addresses_empty": ["ar": "أضف بيانات التوصيل لتسريع الطلب."]
        ,"saved_addresses_singular": ["ar": "عنوان واحد جاهز للاستخدام."]
        ,"saved_addresses_plural": ["ar": "%d عناوين جاهزة للاستخدام."]
        ,"recent_orders": ["ar": "الطلبات الأخيرة"]
        ,"recent_orders_empty": ["ar": "سيظهر طلبك القادم هنا."]
        ,"recent_orders_singular": ["ar": "طلب واحد متاح في سجلّك."]
        ,"recent_orders_plural": ["ar": "%d طلبات متاحة في سجلّك."]
        ,"profile_workspace": ["ar": "مساحة الملف الشخصي"]
        ,"profile_workspace_detail": ["ar": "عدّل بيانات الحساب، وحدّث كلمة المرور، وراجع أحدث الطلبات."]
        ,"order_history": ["ar": "سجل الطلبات"]
        ,"loading_orders": ["ar": "جارٍ تحميل الطلبات..."]
        ,"no_saved_orders": ["ar": "لا توجد طلبات محفوظة بعد."]
        ,"buy_again": ["ar": "اطلب مرة أخرى"]
        ,"loading_wallet_pass": ["ar": "جارٍ تحميل بطاقة Wallet..."]
        ,"add_to_apple_wallet": ["ar": "أضف إلى Apple Wallet"]
        ,"your_cart": ["ar": "سلتك"]
        ,"saved_carts": ["ar": "السلال المحفوظة"]
        ,"saved_carts_empty": ["ar": "احفظ سلة ممتلئة من الحقيبة وارجع إليها عندما تصبح جاهزاً لإتمام الطلب."]
        ,"load": ["ar": "تحميل"]
        ,"start_here": ["ar": "ابدأ من هنا"]
        ,"shop_bestsellers": ["ar": "تسوق الأكثر طلباً"]
        ,"shop_bestsellers_detail": ["ar": "انتقل مباشرة إلى القهوة والأدوات والهدايا."]
        ,"check_rewards_home": ["ar": "تحقق من المكافآت"]
        ,"check_rewards_home_detail": ["ar": "اعرض Beans والمكافآت وحالة العضوية."]
        ,"reorder_faster": ["ar": "أعد الطلب أسرع"]
        ,"reorder_faster_detail": ["ar": "افتح السلال المحفوظة والعناوين والطلبات الأخيرة."]
        ,"brew_better": ["ar": "حضّر بشكل أفضل"]
        ,"brew_better_detail": ["ar": "استخدم الأدلة والوصفات المحفوظة لكوبك القادم."]
        ,"rewards_button": ["ar": "المكافآت"]
        ,"reward_progress_home": ["ar": "تقدم المكافأة"]
        ,"rewards_active_count": ["ar": "%d مكافآت نشطة"]
        ,"roastery": ["ar": "المحمصة"]
        ,"coffee_daily_rituals": ["ar": "قهوة للطقوس اليومية"]
        ,"fresh_roast": ["ar": "تحميص طازج"]
        ,"hero_title": ["ar": "قهوة مختصة،\nمحمصة بعناية"]
        ,"hero_subtitle": ["ar": "تسوّق القهوة المحمصة، وأساسيات التحضير، والمكافآت بدون التنقل المرهق داخل التطبيق."]
        ,"explore_coffees": ["ar": "استكشف القهوة"]
        ,"brewing_guide": ["ar": "دليل التحضير"]
        ,"roastery_selection": ["ar": "اختيارات المحمصة"]
        ,"signature_roasts": ["ar": "تحميصات مميزة"]
        ,"browse_shop": ["ar": "تصفح المتجر"]
        ,"from_the_roastery": ["ar": "من المحمصة"]
        ,"from_the_roastery_detail": ["ar": "تشكيلة أدق من القهوة والأدوات والهدايا، مصممة حول طقس المحمصة اليومي."]
        ,"full_catalog": ["ar": "الكتالوج الكامل"]
        ,"account_tools": ["ar": "أدوات الحساب"]
        ,"talla_account": ["ar": "حساب Talla"]
        ,"talla_account_detail": ["ar": "يربط حساب Talla بين الطلب والمكافآت والبيانات المحفوظة في مكان واحد."]
        ,"rewards_ready": ["ar": "المكافآت جاهزة"]
        ,"rewards_ready_detail": ["ar": "يُستخدم بريد حسابك لإبقاء المكافآت والولاء متزامنين داخل التطبيق."]
        ,"support": ["ar": "الدعم"]
        ,"support_detail": ["ar": "تحتاج مساعدة في الطلبات أو المكافآت؟ تواصل مباشرة مع فريق المحمصة."]
        ,"whatsapp_us": ["ar": "راسلنا واتساب"]
        ,"favorites": ["ar": "المفضلة"]
        ,"favorites_empty": ["ar": "احفظ القهوة والأدوات والهدايا التي تريد العودة إليها."]
        ,"browse_products": ["ar": "تصفح المنتجات"]
        ,"recommended_for_you": ["ar": "موصى به لك"]
        ,"recommendations_empty": ["ar": "ستظهر التوصيات هنا بعد تحميل المنتجات."]
        ,"recommendations_detail": ["ar": "مختارة من القهوة والأدوات والفئات التي تعود إليها باستمرار."]
        ,"alerts": ["ar": "التنبيهات"]
        ,"alerts_empty": ["ar": "اضغط الجرس على أي منتج لإبقائه في قائمة المتابعة عند عودته أو عند نزول تحميص جديد."]
        ,"alerts_detail": ["ar": "تابع الإصدارات القادمة وارجع إلى أنواع القهوة التي لا تريد أن تفوتك."]
        ,"recent_alert_updates": ["ar": "آخر تحديثات التنبيهات"]
        ,"enable": ["ar": "تفعيل"]
        ,"delivery_details": ["ar": "تفاصيل التوصيل"]
        ,"delivery_details_empty": ["ar": "أضف عنواناً لتسريع الطلب."]
        ,"delivery_details_ready_one": ["ar": "عنوان محفوظ واحد جاهز."]
        ,"delivery_details_ready_many": ["ar": "%d عناوين محفوظة جاهزة."]
        ,"delivery_details_hint": ["ar": "احفظ عنوانك المفضل هنا ليصبح إتمام الطلب أسرع حتى عند فتح Shopify على الويب."]
        ,"label": ["ar": "التسمية"]
        ,"full_name": ["ar": "الاسم الكامل"]
        ,"phone": ["ar": "الهاتف"]
        ,"address_line": ["ar": "سطر العنوان"]
        ,"city": ["ar": "المدينة"]
        ,"notes": ["ar": "ملاحظات"]
        ,"save_address": ["ar": "حفظ العنوان"]
        ,"no_saved_addresses": ["ar": "لا توجد عناوين محفوظة بعد."]
        ,"preferred": ["ar": "المفضل"]
        ,"saved_brew_recipes": ["ar": "وصفات التحضير المحفوظة"]
        ,"saved_brew_recipes_empty": ["ar": "احفظ نسب القهوة إلى الماء المفضلة من تبويب التحضير وستظهر هنا."]
        ,"apply": ["ar": "تطبيق"]
        ,"recently_viewed": ["ar": "شوهد مؤخراً"]
        ,"recently_viewed_empty": ["ar": "المنتجات التي تفتحها أو تحفظها أو تضيفها إلى السلة ستظهر هنا للعودة السريعة."]
        ,"by_chef_ahmad": ["ar": "من الشيف أحمد"]
        ,"your_bag_is_empty": ["ar": "حقيبتك فارغة."]
        ,"preferred_delivery": ["ar": "التوصيل المفضل"]
        ,"edit": ["ar": "تعديل"]
        ,"delivery_address_needed": ["ar": "مطلوب عنوان توصيل"]
        ,"add_preferred_address_before_checkout": ["ar": "أضف عنوانك المفضل قبل إتمام الطلب."]
        ,"rewards_voucher": ["ar": "المكافآت والقسيمة"]
        ,"rewards_voucher_detail": ["ar": "طبّق مكافأة قبل فتح الدفع، أو تابع بدونها."]
        ,"enter_voucher_code": ["ar": "أدخل رمز القسيمة"]
        ,"remove": ["ar": "إزالة"]
        ,"discount_expires": ["ar": "الخصم: %@ • ينتهي %@"]
        ,"your_active_vouchers": ["ar": "قسائمك النشطة"]
        ,"active_vouchers_empty": ["ar": "استبدل مكافأة في الحساب لتظهر قسائمك النشطة هنا."]
        ,"shop_load_failed": ["ar": "تعذر تحميل المتجر."]
        ,"checkout_ready": ["ar": "جاهز للطلب"]
        ,"items": ["ar": "العناصر"]
        ,"items_ready": ["ar": "%d في الحقيبة • %d جاهزة"]
        ,"voucher_none": ["ar": "لا يوجد تطبيق بعد"]
        ,"order_summary": ["ar": "ملخص الطلب"]
        ,"subtotal": ["ar": "المجموع الفرعي"]
        ,"total": ["ar": "الإجمالي"]
        ,"opening_checkout": ["ar": "جارٍ فتح الدفع..."]
        ,"open_checkout": ["ar": "فتح الدفع"]
        ,"secure_checkout_handoff": ["ar": "تابع إلى صفحة الدفع الآمنة."]
        ,"save_cart": ["ar": "حفظ السلة"]
        ,"save_cart_placeholder": ["ar": "بن الأسبوع، طلب هدية، طلب المكتب..."]
        ,"checkout_only_iphone": ["ar": "الدفع متاح على iPhone فقط."]
        ,"enter_email_password": ["ar": "أدخل بريد العميل الإلكتروني وكلمة المرور."]
        ,"signed_in_toast": ["ar": "تم تسجيل الدخول"]
        ,"apple_sign_in_unavailable": ["ar": "تسجيل الدخول عبر Apple غير متاح حالياً."]
        ,"apple_sign_in_invalid_credential": ["ar": "لم يُرجع تسجيل الدخول عبر Apple بيانات حساب صالحة."]
        ,"apple_sign_in_missing_token": ["ar": "لم يُرجع تسجيل الدخول عبر Apple رمز الهوية."]
        ,"apple_sign_in_not_verified": ["ar": "تعذر التحقق من تسجيل الدخول عبر Apple."]
        ,"signed_in_with_apple_toast": ["ar": "تم تسجيل الدخول عبر Apple"]
        ,"complete_account_fields": ["ar": "أكمل الاسم والبريد الإلكتروني وكلمة المرور لإنشاء الحساب."]
        ,"password_confirmation_mismatch": ["ar": "تأكيد كلمة المرور غير متطابق."]
        ,"password_min_length": ["ar": "استخدم كلمة مرور لا تقل عن 5 أحرف."]
        ,"account_created_toast": ["ar": "تم إنشاء الحساب"]
        ,"enter_email_first": ["ar": "أدخل بريدك الإلكتروني أولاً."]
        ,"reset_link_sent": ["ar": "إذا كان هناك حساب لهذا البريد الإلكتروني، فقد تم إرسال رابط إعادة التعيين."]
        ,"enter_full_name_before_saving": ["ar": "أدخل الاسم الأول واسم العائلة قبل الحفظ."]
        ,"profile_updated_toast": ["ar": "تم تحديث الملف الشخصي"]
        ,"new_password_confirmation_mismatch": ["ar": "تأكيد كلمة المرور الجديدة غير متطابق."]
        ,"enter_email_current_new_password": ["ar": "أدخل بريدك الإلكتروني وكلمة المرور الحالية والجديدة."]
        ,"complete_address_details": ["ar": "أكمل تفاصيل العنوان أولاً"]
        ,"address_saved_toast": ["ar": "تم حفظ العنوان"]
        ,"address_removed_toast": ["ar": "تمت إزالة العنوان"]
        ,"brewing_articles_fallback": ["ar": "تعذر تحميل مقالات التحضير من Shopify. يتم عرض الأدلة البديلة المختارة."]
        ,"enter_order_email_loyalty": ["ar": "أدخل البريد الإلكتروني الذي تستخدمه لطلبات القهوة."]
        ,"rewards_loaded_toast": ["ar": "تم تحميل المكافآت"]
        ,"enter_rewards_email_first": ["ar": "أدخل البريد الإلكتروني المرتبط بحساب المكافآت أولاً."]
        ,"reward_redeemed_with_code": ["ar": "تم استبدال %@ • %@"]
        ,"reward_redeemed": ["ar": "تم استبدال %@"]
        ,"beans_added_toast": ["ar": "تمت إضافة %d Beans"]
        ,"product_unavailable_toast": ["ar": "%@ غير متوفر"]
        ,"product_added_to_cart": ["ar": "تمت إضافة %@%@ إلى السلة"]
        ,"enter_valid_brew_recipe": ["ar": "أدخل وصفة تحضير صالحة أولاً"]
        ,"brew_recipe_saved_toast": ["ar": "تم حفظ وصفة التحضير"]
        ,"recipe_loaded_toast": ["ar": "تم تحميل %@"]
        ,"brew_recipe_deleted_toast": ["ar": "تم حذف وصفة التحضير"]
        ,"add_items_before_saving_cart": ["ar": "أضف عناصر قبل حفظ السلة"]
        ,"cart_saved_toast": ["ar": "تم حفظ السلة"]
        ,"saved_cart_unavailable": ["ar": "عناصر السلة المحفوظة غير متوفرة حالياً"]
        ,"saved_cart_loaded_toast": ["ar": "تم تحميل %@"]
        ,"saved_cart_deleted_toast": ["ar": "تم حذف السلة المحفوظة"]
        ,"removed_from_favorites": ["ar": "تمت الإزالة من المفضلة"]
        ,"saved_to_favorites": ["ar": "تم الحفظ في المفضلة"]
        ,"removed_from_alerts": ["ar": "تمت الإزالة من التنبيهات"]
        ,"added_to_alerts": ["ar": "تمت الإضافة إلى التنبيهات"]
        ,"notifications_enabled": ["ar": "تم تفعيل الإشعارات"]
        ,"notifications_not_enabled": ["ar": "لم يتم تفعيل الإشعارات"]
        ,"items_unavailable_currently": ["ar": "هذه العناصر غير متوفرة حالياً"]
        ,"order_added_to_cart": ["ar": "تمت إضافة الطلب إلى السلة"]
        ,"available_items_added_from_order": ["ar": "تمت إضافة العناصر المتوفرة من ذلك الطلب"]
        ,"sign_in_to_apply_voucher": ["ar": "سجّل الدخول لتطبيق قسيمة المكافآت."]
        ,"enter_voucher_code_first": ["ar": "أدخل رمز القسيمة أولاً."]
        ,"voucher_applied_toast": ["ar": "تم تطبيق القسيمة"]
        ,"cart_no_purchasable_items": ["ar": "لا توجد عناصر قابلة للشراء في سلتك."]
        ,"checkout_opened_toast": ["ar": "تم فتح صفحة الدفع"]
        ,"apple_wallet_unavailable": ["ar": "Apple Wallet غير متوفر على هذا الجهاز"]
        ,"sign_in_before_wallet_pass": ["ar": "سجّل الدخول قبل إضافة بطاقتك إلى Wallet"]
        ,"wallet_pass_already_added": ["ar": "بطاقة الولاء موجودة بالفعل في Apple Wallet"]
    ]

    static var currentLanguage: AppLanguage {
        let rawValue = UserDefaults.standard.string(forKey: "app.language") ?? AppLanguage.system.rawValue
        return AppLanguage(rawValue: rawValue) ?? .system
    }

    static func text(_ key: String, fallback: String) -> String {
        let languageCode = currentLanguage.effectiveLanguageCode
        return translations[key]?[languageCode] ?? fallback
    }
}

enum BackendConfiguration {
    private static let infoPlistKey = "BackendBaseURL"
    private static let simulatorDefaultURL = URL(string: "http://127.0.0.1:8787")

    static var serviceBaseURL: URL? {
        if let configuredURL {
            return configuredURL
        }

        #if targetEnvironment(simulator)
        return simulatorDefaultURL
        #else
        return nil
        #endif
    }

    static func unavailableMessage(for serviceName: String) -> String {
        "\(serviceName) is unavailable. Set `BackendBaseURL` in Info.plist to your Mac's local network address, for example `http://192.168.1.23:8787`, or use a real HTTPS backend."
    }

    static func connectionMessage(for serviceName: String) -> String {
        "Could not reach the \(serviceName.lowercased()). On iPhone, `127.0.0.1` and `localhost` point to the phone itself. Set `BackendBaseURL` in Info.plist to your Mac's local network address, then make sure the backend server is running and reachable on the same Wi-Fi network."
    }

    private static var configuredURL: URL? {
        guard let rawValue = Bundle.main.object(forInfoDictionaryKey: infoPlistKey) as? String else {
            return nil
        }

        let trimmedValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty, let url = URL(string: trimmedValue) else {
            return nil
        }

        #if targetEnvironment(simulator)
        return url
        #else
        guard let host = url.host?.lowercased(), host != "127.0.0.1", host != "localhost" else {
            return nil
        }
        return url
        #endif
    }
}

#if canImport(UserNotifications)
private enum ProductAlertNotificationService {
    private static let center = UNUserNotificationCenter.current()

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await withCheckedContinuation { continuation in
            center.getNotificationSettings { settings in
                continuation.resume(returning: settings.authorizationStatus)
            }
        }
    }

    static func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }

    static func scheduleReminder(for productID: String, title: String, body: String) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: reminderIdentifier(for: productID),
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 86_400, repeats: false)
        )

        do {
            try await center.add(request)
        } catch {
            return
        }
    }

    static func removeReminder(for productID: String) async {
        center.removePendingNotificationRequests(withIdentifiers: [reminderIdentifier(for: productID)])
    }

    private static func reminderIdentifier(for productID: String) -> String {
        "product-alert-\(productID)"
    }
}
#endif

private enum AccountService {
    private static let baseURL = BackendConfiguration.serviceBaseURL

    static func register(firstName: String, lastName: String, email: String, password: String) async throws -> ContentView.ShopifyCustomerProfile {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed(BackendConfiguration.unavailableMessage(for: "Account service"))
        }

        var request = URLRequest(url: baseURL.appending(path: "/accounts/register"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "firstName": firstName,
            "lastName": lastName,
            "email": email,
            "password": password
        ])

        return try await performProfileRequest(request)
    }

    static func signIn(email: String, password: String) async throws -> ContentView.ShopifyCustomerProfile {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The account service is unavailable.")
        }

        var request = URLRequest(url: baseURL.appending(path: "/accounts/login"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "password": password
        ])

        return try await performProfileRequest(request)
    }

    static func fetchProfile(email: String) async throws -> ContentView.ShopifyCustomerProfile {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The account service is unavailable.")
        }

        var components = URLComponents(url: baseURL.appending(path: "/accounts/profile"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "email", value: email)]

        guard let url = components?.url else {
            throw ContentView.LoyaltyServiceError.operationFailed("The account service URL is invalid.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        return try await performProfileRequest(request)
    }

    static func updateProfile(email: String, firstName: String, lastName: String) async throws -> ContentView.ShopifyCustomerProfile {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The account service is unavailable.")
        }

        var request = URLRequest(url: baseURL.appending(path: "/accounts/profile/update"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "firstName": firstName,
            "lastName": lastName
        ])

        return try await performProfileRequest(request)
    }

    static func resetPassword(email: String, currentPassword: String, newPassword: String) async throws {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The account service is unavailable.")
        }

        var request = URLRequest(url: baseURL.appending(path: "/accounts/password/reset"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "currentPassword": currentPassword,
            "newPassword": newPassword
        ])

        _ = try await performEmptyRequest(request)
    }

    static func fetchOrders(email: String) async throws -> [ContentView.AccountOrder] {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The orders service is unavailable.")
        }

        var components = URLComponents(url: baseURL.appending(path: "/orders"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "email", value: email)]

        guard let url = components?.url else {
            throw ContentView.LoyaltyServiceError.operationFailed("The orders service URL is invalid.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        return try await performOrdersRequest(request)
    }

    static func createSampleOrder(email: String) async throws -> [ContentView.AccountOrder] {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The orders service is unavailable.")
        }

        var request = URLRequest(url: baseURL.appending(path: "/orders/sample"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email
        ])

        return try await performOrdersRequest(request)
    }

    static func fetchStockAlerts(email: String) async throws -> [ContentView.StockAlertRecord] {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The alerts service is unavailable.")
        }

        var components = URLComponents(url: baseURL.appending(path: "/alerts"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "email", value: email)]

        guard let url = components?.url else {
            throw ContentView.LoyaltyServiceError.operationFailed("The alerts service URL is invalid.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        return try await performStockAlertsRequest(request)
    }

    static func fetchAlertInbox(email: String) async throws -> [ContentView.AlertInboxRecord] {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The alerts service is unavailable.")
        }

        var components = URLComponents(url: baseURL.appending(path: "/alerts/inbox"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "email", value: email)]

        guard let url = components?.url else {
            throw ContentView.LoyaltyServiceError.operationFailed("The alerts inbox URL is invalid.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        return try await performAlertInboxRequest(request)
    }

    static func watchStockAlert(email: String, alert: ContentView.StockAlertRecord) async throws -> ContentView.StockAlertRecord {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The alerts service is unavailable.")
        }

        var payload = [
            "email": email,
            "productID": alert.productID,
            "productName": alert.productName,
            "isAvailableForSale": alert.isAvailableForSale
        ] as [String: Any]
        if let tag = alert.tag {
            payload["tag"] = tag
        }

        var request = URLRequest(url: baseURL.appending(path: "/alerts/watch"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        return try await performStockAlertRequest(request)
    }

    static func removeStockAlert(email: String, productID: String) async throws {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The alerts service is unavailable.")
        }

        var request = URLRequest(url: baseURL.appending(path: "/alerts/unwatch"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "productID": productID
        ])

        _ = try await performEmptyRequest(request)
    }

    static func syncStockAlerts(email: String, alerts: [ContentView.StockAlertRecord]) async throws -> [ContentView.StockAlertRecord] {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The alerts service is unavailable.")
        }

        let payloadAlerts = alerts.map { alert -> [String: Any] in
            var payload: [String: Any] = [
                "productID": alert.productID,
                "productName": alert.productName,
                "isAvailableForSale": alert.isAvailableForSale
            ]
            if let tag = alert.tag {
                payload["tag"] = tag
            }
            return payload
        }

        var request = URLRequest(url: baseURL.appending(path: "/alerts/sync"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "alerts": payloadAlerts
        ])

        return try await performStockAlertsRequest(request)
    }

    static func fetchAddresses(email: String) async throws -> [ContentView.DeliveryAddress] {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The address service is unavailable.")
        }

        var components = URLComponents(url: baseURL.appending(path: "/addresses"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "email", value: email)]

        guard let url = components?.url else {
            throw ContentView.LoyaltyServiceError.operationFailed("The address service URL is invalid.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        return try await performAddressesRequest(request)
    }

    static func saveAddress(email: String, label: String, fullName: String, phone: String, line1: String, city: String, notes: String?) async throws -> [ContentView.DeliveryAddress] {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The address service is unavailable.")
        }

        var payload: [String: Any] = [
            "email": email,
            "label": label,
            "fullName": fullName,
            "phone": phone,
            "line1": line1,
            "city": city
        ]
        if let notes {
            payload["notes"] = notes
        }

        var request = URLRequest(url: baseURL.appending(path: "/addresses/save"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        return try await performAddressesRequest(request)
    }

    static func deleteAddress(email: String, addressID: String) async throws -> [ContentView.DeliveryAddress] {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The address service is unavailable.")
        }

        var request = URLRequest(url: baseURL.appending(path: "/addresses/delete"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "addressID": addressID
        ])

        return try await performAddressesRequest(request)
    }

    static func fetchVouchers(email: String) async throws -> [ContentView.VoucherRecord] {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The voucher service is unavailable.")
        }

        var components = URLComponents(url: baseURL.appending(path: "/vouchers"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "email", value: email)]

        guard let url = components?.url else {
            throw ContentView.LoyaltyServiceError.operationFailed("The voucher service URL is invalid.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        return try await performVouchersRequest(request)
    }

    static func previewVoucher(code: String, email: String) async throws -> ContentView.VoucherRecord {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The voucher service is unavailable.")
        }

        var request = URLRequest(url: baseURL.appending(path: "/vouchers/preview"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "code": code,
            "email": email
        ])

        return try await performVoucherRequest(request)
    }

    static func consumeVoucher(code: String, email: String) async throws -> ContentView.VoucherRecord {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The voucher service is unavailable.")
        }

        var request = URLRequest(url: baseURL.appending(path: "/vouchers/consume"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "code": code,
            "email": email
        ])

        return try await performVoucherRequest(request)
    }

#if canImport(PassKit)
    static func fetchWalletPass(email: String) async throws -> PKPass {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The wallet service is unavailable.")
        }

        var components = URLComponents(url: baseURL.appending(path: "/wallet/pass"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "email", value: email)]

        guard let url = components?.url else {
            throw ContentView.LoyaltyServiceError.operationFailed("The wallet service URL is invalid.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The wallet service returned an invalid response.")
        }

        if 200 ..< 300 ~= httpResponse.statusCode {
            return try await Task.detached(priority: .userInitiated) {
                guard let pass = try? PKPass(data: data) else {
                    throw ContentView.LoyaltyServiceError.operationFailed("The Wallet pass could not be loaded.")
                }
                return pass
            }.value
        }

        if let errorPayload = try? JSONDecoder().decode(ServiceErrorResponse.self, from: data) {
            throw ContentView.LoyaltyServiceError.operationFailed(errorPayload.error)
        }

        throw ContentView.LoyaltyServiceError.operationFailed("The wallet service could not complete your request.")
    }
#endif

    private static func performProfileRequest(_ request: URLRequest) async throws -> ContentView.ShopifyCustomerProfile {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The account service returned an invalid response.")
        }

        if 200 ..< 300 ~= httpResponse.statusCode {
            let decoded = try JSONDecoder().decode(AccountProfileResponse.self, from: data)
            return ContentView.ShopifyCustomerProfile(
                id: decoded.id,
                firstName: decoded.firstName,
                lastName: decoded.lastName,
                email: decoded.email
            )
        }

        if let errorPayload = try? JSONDecoder().decode(ServiceErrorResponse.self, from: data) {
            throw ContentView.LoyaltyServiceError.operationFailed(errorPayload.error)
        }

        throw ContentView.LoyaltyServiceError.operationFailed("The account service could not complete your request.")
    }

    private static func performOrdersRequest(_ request: URLRequest) async throws -> [ContentView.AccountOrder] {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The orders service returned an invalid response.")
        }

        if 200 ..< 300 ~= httpResponse.statusCode {
            return try JSONDecoder().decode([ContentView.AccountOrder].self, from: data)
        }

        if let errorPayload = try? JSONDecoder().decode(ServiceErrorResponse.self, from: data) {
            throw ContentView.LoyaltyServiceError.operationFailed(errorPayload.error)
        }

        throw ContentView.LoyaltyServiceError.operationFailed("The orders service could not complete your request.")
    }

    private static func performVouchersRequest(_ request: URLRequest) async throws -> [ContentView.VoucherRecord] {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The voucher service returned an invalid response.")
        }

        if 200 ..< 300 ~= httpResponse.statusCode {
            return try JSONDecoder().decode([ContentView.VoucherRecord].self, from: data)
        }

        if let errorPayload = try? JSONDecoder().decode(ServiceErrorResponse.self, from: data) {
            throw ContentView.LoyaltyServiceError.operationFailed(errorPayload.error)
        }

        throw ContentView.LoyaltyServiceError.operationFailed("The voucher service could not complete your request.")
    }

    private static func performStockAlertsRequest(_ request: URLRequest) async throws -> [ContentView.StockAlertRecord] {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The alerts service returned an invalid response.")
        }

        if 200 ..< 300 ~= httpResponse.statusCode {
            return try JSONDecoder().decode([ContentView.StockAlertRecord].self, from: data)
        }

        if let errorPayload = try? JSONDecoder().decode(ServiceErrorResponse.self, from: data) {
            throw ContentView.LoyaltyServiceError.operationFailed(errorPayload.error)
        }

        throw ContentView.LoyaltyServiceError.operationFailed("The alerts service could not complete your request.")
    }

    private static func performStockAlertRequest(_ request: URLRequest) async throws -> ContentView.StockAlertRecord {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The alerts service returned an invalid response.")
        }

        if 200 ..< 300 ~= httpResponse.statusCode {
            return try JSONDecoder().decode(ContentView.StockAlertRecord.self, from: data)
        }

        if let errorPayload = try? JSONDecoder().decode(ServiceErrorResponse.self, from: data) {
            throw ContentView.LoyaltyServiceError.operationFailed(errorPayload.error)
        }

        throw ContentView.LoyaltyServiceError.operationFailed("The alerts service could not complete your request.")
    }

    private static func performAlertInboxRequest(_ request: URLRequest) async throws -> [ContentView.AlertInboxRecord] {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The alerts inbox returned an invalid response.")
        }

        if 200 ..< 300 ~= httpResponse.statusCode {
            return try JSONDecoder().decode([ContentView.AlertInboxRecord].self, from: data)
        }

        if let errorPayload = try? JSONDecoder().decode(ServiceErrorResponse.self, from: data) {
            throw ContentView.LoyaltyServiceError.operationFailed(errorPayload.error)
        }

        throw ContentView.LoyaltyServiceError.operationFailed("The alerts inbox could not complete your request.")
    }

    private static func performAddressesRequest(_ request: URLRequest) async throws -> [ContentView.DeliveryAddress] {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The address service returned an invalid response.")
        }

        if 200 ..< 300 ~= httpResponse.statusCode {
            return try JSONDecoder().decode([ContentView.DeliveryAddress].self, from: data)
        }

        if let errorPayload = try? JSONDecoder().decode(ServiceErrorResponse.self, from: data) {
            throw ContentView.LoyaltyServiceError.operationFailed(errorPayload.error)
        }

        throw ContentView.LoyaltyServiceError.operationFailed("The address service could not complete your request.")
    }

    private static func performVoucherRequest(_ request: URLRequest) async throws -> ContentView.VoucherRecord {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The voucher service returned an invalid response.")
        }

        if 200 ..< 300 ~= httpResponse.statusCode {
            return try JSONDecoder().decode(ContentView.VoucherRecord.self, from: data)
        }

        if let errorPayload = try? JSONDecoder().decode(ServiceErrorResponse.self, from: data) {
            throw ContentView.LoyaltyServiceError.operationFailed(errorPayload.error)
        }

        throw ContentView.LoyaltyServiceError.operationFailed("The voucher service could not complete your request.")
    }

    private static func performEmptyRequest(_ request: URLRequest) async throws -> Bool {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The service returned an invalid response.")
        }

        if 200 ..< 300 ~= httpResponse.statusCode {
            return true
        }

        if let errorPayload = try? JSONDecoder().decode(ServiceErrorResponse.self, from: data) {
            throw ContentView.LoyaltyServiceError.operationFailed(errorPayload.error)
        }

        throw ContentView.LoyaltyServiceError.operationFailed("The service could not complete your request.")
    }
}

private enum LoyaltyService {
    private static let baseURL = BackendConfiguration.serviceBaseURL

    static func fetchAccount(email: String) async throws -> ContentView.LoyaltyAccount {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed(BackendConfiguration.unavailableMessage(for: "Loyalty service"))
        }

        var components = URLComponents(url: baseURL.appending(path: "/loyalty/account"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "email", value: email)]

        guard let url = components?.url else {
            throw ContentView.LoyaltyServiceError.operationFailed("The loyalty service URL is invalid.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        return try await performLoyaltyRequest(request)
    }

    static func redeemReward(email: String, points: Int, reward: String) async throws -> ContentView.LoyaltyAccount {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The loyalty service is unavailable.")
        }

        var request = URLRequest(url: baseURL.appending(path: "/loyalty/redeem"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "points": points,
            "reward": reward
        ])

        return try await performLoyaltyRequest(request)
    }

    static func earnPoints(email: String, points: Int, note: String) async throws -> ContentView.LoyaltyAccount {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The loyalty service is unavailable.")
        }

        var request = URLRequest(url: baseURL.appending(path: "/loyalty/earn"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "points": points,
            "note": note
        ])

        return try await performLoyaltyRequest(request)
    }

    private static func performLoyaltyRequest(_ request: URLRequest) async throws -> ContentView.LoyaltyAccount {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The loyalty service returned an invalid response.")
        }

        if 200 ..< 300 ~= httpResponse.statusCode {
            return try JSONDecoder().decode(ContentView.LoyaltyAccount.self, from: data)
        }

        if let errorPayload = try? JSONDecoder().decode(ServiceErrorResponse.self, from: data) {
            throw ContentView.LoyaltyServiceError.operationFailed(errorPayload.error)
        }

        throw ContentView.LoyaltyServiceError.operationFailed("The loyalty service could not complete your request.")
    }
}

#if canImport(PassKit) && canImport(UIKit)
private struct WalletPassView: UIViewControllerRepresentable {
    let pass: PKPass

    func makeUIViewController(context: Context) -> UIViewController {
        guard let controller = PKAddPassesViewController(pass: pass) else {
            return UIViewController()
        }

        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    }
}
#endif

#if canImport(SafariServices) && canImport(UIKit)
private struct CheckoutWebView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let configuration = SFSafariViewController.Configuration()
        configuration.entersReaderIfAvailable = false

        let controller = SFSafariViewController(url: url, configuration: configuration)
        controller.dismissButtonStyle = .close
        return controller
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
    }
}
#else
private struct CheckoutWebView: View {
    let url: URL

    var body: some View {
        VStack(spacing: 16) {
            Text("Checkout is only available on iPhone.")
                .font(.headline)
            Text(url.absoluteString)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding(24)
    }
}
#endif

private enum ShopifyStorefrontClient {
    private static let endpoint = URL(string: "https://\(ShopifyConfiguration.shopDomain)/api/2025-10/graphql.json")!

    static func fetchAllProducts() async throws -> [ContentView.Product] {
        var products: [ContentView.Product] = []
        var cursor: String?
        var hasNextPage = true

        while hasNextPage {
            let response = try await fetchPage(after: cursor)

            products.append(contentsOf: response.products.edges.compactMap { edge in
                guard ContentView.Product.shouldInclude(shopifyNode: edge.node) else {
                    return nil
                }
                return ContentView.Product(shopifyNode: edge.node)
            })

            hasNextPage = response.products.pageInfo.hasNextPage
            cursor = response.products.pageInfo.endCursor
        }

        return products
    }

    static func fetchBrewingMethods() async throws -> [ContentView.BrewingMethod] {
        let body = ShopifyGraphQLRequest(
            query: """
            query BrewingArticles($handle: String!, $query: String!) {
              blog(handle: $handle) {
                articles(first: 12) {
                  edges {
                    node {
                      id
                      handle
                      title
                      excerpt
                      content(truncateAt: 180)
                      tags
                      onlineStoreUrl
                      blog {
                        handle
                        title
                      }
                    }
                  }
                }
              }
              articles(first: 12, sortKey: PUBLISHED_AT, reverse: true, query: $query) {
                edges {
                  node {
                    id
                    handle
                    title
                    excerpt
                    content(truncateAt: 180)
                    tags
                    onlineStoreUrl
                    blog {
                      handle
                      title
                    }
                  }
                }
              }
            }
            """,
            variables: [
                "handle": ShopifyConfiguration.brewingBlogHandle,
                "query": ShopifyConfiguration.brewingArticlesQuery
            ]
        )

        let decoded: ShopifyBrewingArticlesResponse = try await performRequest(body)

        if let errors = decoded.errors, let first = errors.first {
            throw ShopifyError.api(first.message)
        }

        let nodesFromBlog = decoded.data?.blog?.articles.edges.map(\.node) ?? []
        let fallbackNodes = decoded.data?.articles.edges.map(\.node) ?? []
        let selectedNodes = nodesFromBlog.isEmpty ? fallbackNodes : nodesFromBlog

        guard !selectedNodes.isEmpty else {
            throw ShopifyError.api("No brewing articles are available in Shopify yet.")
        }

        return selectedNodes.map(ContentView.BrewingMethod.init(article:))
    }

    static func createCustomerAccessToken(email: String, password: String) async throws -> ShopifyCustomerSession {
        let body = ShopifyGraphQLRequest(
            query: """
            mutation CustomerAccessTokenCreate($input: CustomerAccessTokenCreateInput!) {
              customerAccessTokenCreate(input: $input) {
                customerAccessToken {
                  accessToken
                  expiresAt
                }
                customerUserErrors {
                  message
                }
              }
            }
            """,
            variables: [
                "input": [
                    "email": email,
                    "password": password
                ]
            ]
        )

        let decoded: ShopifyCustomerAccessTokenCreateResponse = try await performRequest(body)

        if let errors = decoded.errors, let first = errors.first {
            throw ShopifyError.api(first.message)
        }

        if let userError = decoded.data?.customerAccessTokenCreate.customerUserErrors.first {
            throw ShopifyError.api(userError.message)
        }

        guard let session = decoded.data?.customerAccessTokenCreate.customerAccessToken else {
            throw ShopifyError.invalidResponse
        }

        return session
    }

    static func createCustomer(firstName: String, lastName: String, email: String, password: String) async throws -> ShopifyCustomerCreateResponse.CreatedCustomer {
        let body = ShopifyGraphQLRequest(
            query: """
            mutation CustomerCreate($input: CustomerCreateInput!) {
              customerCreate(input: $input) {
                customer {
                  id
                }
                customerUserErrors {
                  message
                }
              }
            }
            """,
            variables: [
                "input": [
                    "firstName": firstName,
                    "lastName": lastName,
                    "email": email,
                    "password": password
                ]
            ]
        )

        let decoded: ShopifyCustomerCreateResponse = try await performRequest(body)

        if let errors = decoded.errors, let first = errors.first {
            throw ShopifyError.api(first.message)
        }

        if let userError = decoded.data?.customerCreate.customerUserErrors.first {
            throw ShopifyError.api(userError.message)
        }

        guard let customer = decoded.data?.customerCreate.customer else {
            throw ShopifyError.invalidResponse
        }

        return customer
    }

    static func fetchCustomer(accessToken: String) async throws -> ContentView.ShopifyCustomerProfile {
        let body = ShopifyGraphQLRequest(
            query: """
            query Customer($customerAccessToken: String!) {
              customer(customerAccessToken: $customerAccessToken) {
                id
                firstName
                lastName
                email
              }
            }
            """,
            variables: [
                "customerAccessToken": accessToken
            ]
        )

        let decoded: ShopifyCustomerQueryResponse = try await performRequest(body)

        if let errors = decoded.errors, let first = errors.first {
            throw ShopifyError.api(first.message)
        }

        guard let customer = decoded.data?.customer else {
            throw ShopifyError.api("Your account session has expired. Please sign in again.")
        }

        return ContentView.ShopifyCustomerProfile(
            id: customer.id,
            firstName: customer.firstName,
            lastName: customer.lastName,
            email: customer.email
        )
    }

    private static func fetchPage(after cursor: String?) async throws -> ShopifyProductsResponse.DataPayload {
        let body = ShopifyGraphQLRequest(
            query: """
            query Products($cursor: String) {
              products(first: 50, after: $cursor, sortKey: TITLE) {
                pageInfo {
                  hasNextPage
                  endCursor
                }
                edges {
                  node {
                    id
                    title
                    description
                    tags
                    productType
                    featuredImage {
                      url
                    }
                    variants(first: 12) {
                      edges {
                        node {
                          id
                          title
                          availableForSale
                          price {
                            amount
                            currencyCode
                          }
                        }
                      }
                    }
                    priceRange {
                      minVariantPrice {
                        amount
                        currencyCode
                      }
                    }
                  }
                }
              }
            }
            """,
            variables: ["cursor": cursor as Any]
        )

        let decoded: ShopifyProductsResponse = try await performRequest(body)

        if let errors = decoded.errors, let first = errors.first {
            throw ShopifyError.api(first.message)
        }

        guard let payload = decoded.data else {
            throw ShopifyError.invalidResponse
        }

        return payload
    }

    static func createCheckoutURL(lines: [ShopifyCheckoutLine], checkoutAddress: ShopifyCheckoutAddress? = nil) async throws -> URL {
        let lineInputs = lines.map { line in
            [
                "merchandiseId": line.merchandiseId,
                "quantity": line.quantity
            ] as [String: Any]
        }

        let input: [String: Any]
        if let checkoutAddress {
            let nameParts = checkoutAddress.fullName
                .split(separator: " ", omittingEmptySubsequences: true)
                .map(String.init)
            let firstName = nameParts.first ?? checkoutAddress.fullName
            let lastName = nameParts.dropFirst().joined(separator: " ")
            let deliveryAddress: [String: Any] = [
                "address1": checkoutAddress.address1,
                "city": checkoutAddress.city,
                "country": "Bahrain",
                "firstName": firstName,
                "lastName": lastName,
                "phone": checkoutAddress.phone
            ]
            let deliveryAddressPreference: [String: Any] = [
                "deliveryAddress": deliveryAddress
            ]
            let buyerIdentity: [String: Any] = [
                "email": checkoutAddress.email,
                "phone": checkoutAddress.phone,
                "deliveryAddressPreferences": [deliveryAddressPreference]
            ]

            input = [
                "lines": lineInputs,
                "buyerIdentity": buyerIdentity
            ]
        } else {
            input = [
                "lines": lineInputs
            ]
        }

        let body = ShopifyGraphQLRequest(
            query: """
            mutation CreateCart($input: CartInput) {
              cartCreate(input: $input) {
                cart {
                  checkoutUrl
                }
                userErrors {
                  message
                }
              }
            }
            """,
            variables: [
                "input": input
            ]
        )

        let decoded: ShopifyCartCreateResponse = try await performRequest(body)

        if let errors = decoded.errors, let first = errors.first {
            throw ShopifyError.api(first.message)
        }

        if let userError = decoded.data?.cartCreate.userErrors.first {
            throw ShopifyError.api(userError.message)
        }

        guard let checkoutURL = decoded.data?.cartCreate.cart?.checkoutUrl else {
            throw ShopifyError.invalidResponse
        }

        return checkoutURL
    }

    private static func performRequest<Response: Decodable>(_ body: ShopifyGraphQLRequest) async throws -> Response {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(ShopifyConfiguration.storefrontToken, forHTTPHeaderField: "X-Shopify-Storefront-Access-Token")
        request.httpBody = try JSONSerialization.data(withJSONObject: body.dictionary, options: [])

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw ShopifyError.invalidResponse
        }

        return try JSONDecoder().decode(Response.self, from: data)
    }
}

private struct ShopifyConfiguration {
    static let shopDomain = "duneroastery.myshopify.com"
    static let storefrontToken = "0b8e38878678cd9b9db8325f88f95141"
    static let accountLoginURL = URL(string: "https://\(shopDomain)/account/login")!
    static let accountRegisterURL = URL(string: "https://\(shopDomain)/account/register")!
    static let brewingBlogHandle = "brewing-methods"
    static let brewingArticlesQuery = "blog_title:\"Brewing Methods\" OR tag:brewing OR tag:brew"
}

private struct ShopifyGraphQLRequest {
    let query: String
    let variables: [String: Any]

    var dictionary: [String: Any] {
        [
            "query": query,
            "variables": variables
        ]
    }
}

private struct ShopifyProductsResponse: Decodable {
    let data: DataPayload?
    let errors: [GraphQLError]?

    struct DataPayload: Decodable {
        let products: ProductConnection
    }

    struct ProductConnection: Decodable {
        let pageInfo: PageInfo
        let edges: [ProductEdge]
    }

    struct PageInfo: Decodable {
        let hasNextPage: Bool
        let endCursor: String?
    }

    struct ProductEdge: Decodable {
        let node: ShopifyProductNode
    }

    struct GraphQLError: Decodable {
        let message: String
    }
}

private struct ShopifyProductNode: Decodable {
    let id: String
    let title: String
    let description: String
    let tags: [String]
    let productType: String
    let featuredImage: FeaturedImage?
    let variants: VariantConnection
    let priceRange: PriceRange

    struct FeaturedImage: Decodable {
        let url: URL
    }

    struct PriceRange: Decodable {
        let minVariantPrice: Money
    }

    struct VariantConnection: Decodable {
        let edges: [VariantEdge]
    }

    struct VariantEdge: Decodable {
        let node: ProductVariant
    }

    struct ProductVariant: Decodable {
        let id: String
        let title: String
        let availableForSale: Bool
        let price: Money
    }

    struct Money: Decodable {
        let amount: String
        let currencyCode: String
    }
}

private enum ShopifyError: LocalizedError {
    case invalidResponse
    case api(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The Shopify response was invalid."
        case .api(let message):
            return message
        }
    }
}

private struct ShopifyCheckoutLine {
    let merchandiseId: String
    let quantity: Int
}

private struct ShopifyCheckoutAddress {
    let email: String
    let fullName: String
    let phone: String
    let address1: String
    let city: String
}

private struct ShopifyCartCreateResponse: Decodable {
    let data: DataPayload?
    let errors: [ShopifyProductsResponse.GraphQLError]?

    struct DataPayload: Decodable {
        let cartCreate: CartCreatePayload
    }

    struct CartCreatePayload: Decodable {
        let cart: Cart?
        let userErrors: [UserError]
    }

    struct Cart: Decodable {
        let checkoutUrl: URL
    }

    struct UserError: Decodable {
        let message: String
    }
}

private struct ShopifyCustomerSession: Decodable {
    let accessToken: String
    let expiresAt: String
}

private struct ShopifyCustomerAccessTokenCreateResponse: Decodable {
    let data: DataPayload?
    let errors: [ShopifyProductsResponse.GraphQLError]?

    struct DataPayload: Decodable {
        let customerAccessTokenCreate: CustomerAccessTokenCreatePayload
    }

    struct CustomerAccessTokenCreatePayload: Decodable {
        let customerAccessToken: ShopifyCustomerSession?
        let customerUserErrors: [ShopifyCustomerUserError]
    }

    struct ShopifyCustomerUserError: Decodable {
        let message: String
    }
}

private struct ShopifyCustomerQueryResponse: Decodable {
    let data: DataPayload?
    let errors: [ShopifyProductsResponse.GraphQLError]?

    struct DataPayload: Decodable {
        let customer: Customer?
    }

    struct Customer: Decodable {
        let id: String
        let firstName: String?
        let lastName: String?
        let email: String
    }
}

private struct ShopifyCustomerCreateResponse: Decodable {
    let data: DataPayload?
    let errors: [ShopifyProductsResponse.GraphQLError]?

    struct DataPayload: Decodable {
        let customerCreate: CustomerCreatePayload
    }

    struct CustomerCreatePayload: Decodable {
        let customer: CreatedCustomer?
        let customerUserErrors: [ShopifyCustomerAccessTokenCreateResponse.ShopifyCustomerUserError]
    }

    struct CreatedCustomer: Decodable {
        let id: String
    }
}

private struct ShopifyBrewingArticlesResponse: Decodable {
    let data: DataPayload?
    let errors: [ShopifyProductsResponse.GraphQLError]?

    struct DataPayload: Decodable {
        let blog: Blog?
        let articles: ArticleConnection
    }

    struct Blog: Decodable {
        let articles: ArticleConnection
    }

    struct ArticleConnection: Decodable {
        let edges: [ArticleEdge]
    }

    struct ArticleEdge: Decodable {
        let node: ArticleNode
    }

    struct ArticleNode: Decodable {
        let id: String
        let handle: String
        let title: String
        let excerpt: String?
        let content: String
        let tags: [String]
        let onlineStoreUrl: URL?
        let blog: BlogSummary
    }

    struct BlogSummary: Decodable {
        let handle: String
        let title: String
    }
}

private struct AccountProfileResponse: Decodable {
    let id: String
    let firstName: String?
    let lastName: String?
    let email: String
}

private struct ServiceErrorResponse: Decodable {
    let error: String
}

private extension ContentView.Product {
    static func shouldInclude(shopifyNode: ShopifyProductNode) -> Bool {
        let source = ([shopifyNode.title, shopifyNode.productType] + shopifyNode.tags)
            .joined(separator: " ")
            .lowercased()

        if source.contains("gift card") || source.contains("giftcard") {
            return false
        }

        return true
    }

    init(shopifyNode: ShopifyProductNode) {
        let categoryKey = Self.categoryKey(
            productType: shopifyNode.productType,
            tags: shopifyNode.tags,
            title: shopifyNode.title
        )
        let variants = shopifyNode.variants.edges.map { edge in
            ContentView.Product.Variant(
                id: edge.node.id,
                title: edge.node.title.isEmpty ? "Default" : edge.node.title,
                price: Self.formattedPrice(from: edge.node.price),
                isAvailableForSale: edge.node.availableForSale
            )
        }
        let defaultVariant = variants.first(where: \.isAvailableForSale) ?? variants.first

        self.init(
            id: shopifyNode.id,
            variantID: defaultVariant?.id,
            variants: variants,
            name: shopifyNode.title,
            price: defaultVariant?.price ?? Self.formattedPrice(from: shopifyNode.priceRange.minVariantPrice),
            categoryKey: categoryKey,
            categoryLabel: Self.categoryLabel(productType: shopifyNode.productType, fallbackKey: categoryKey),
            imageURL: shopifyNode.featuredImage?.url,
            desc: shopifyNode.description.isEmpty ? "Freshly synced from Shopify." : shopifyNode.description,
            tag: Self.productTag(from: shopifyNode.tags),
            isAvailableForSale: defaultVariant?.isAvailableForSale ?? false
        )
    }

    private static func categoryKey(productType: String, tags: [String], title: String) -> String {
        let source = ([title, productType] + tags)
            .joined(separator: " ")
            .lowercased()

        if source.contains("talla box")
            || source.contains("mini talla box")
            || source.contains("mini coffee box")
            || source.contains("mini arabic coffee box") {
            return "gifts"
        }

        if source.contains("shamali coffee") {
            return "arabic-coffee-beans"
        }

        let trimmedType = productType.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedType.isEmpty {
            let sluggedType = slug(from: trimmedType)
            if sluggedType == "northern-coffee" {
                return "arabic-coffee-beans"
            }
            if sluggedType == "tea" {
                return "ready-made-drinks"
            }
            if sluggedType == "desserts" || sluggedType == "spreads" || sluggedType == "bread" {
                return "crmb-tallas-speciality-bakery"
            }
            return sluggedType
        }

        if source.contains("tea") {
            return "ready-made-drinks"
        }

        if source.contains("dessert") || source.contains("bread") || source.contains("jam") || source.contains("spread") || source.contains("butter") || source.contains("cookie") || source.contains("cake") {
            return "crmb-tallas-speciality-bakery"
        }

        if source.contains("gift") || source.contains("bundle") {
            return "gifts"
        }

        if source.contains("turkish") {
            return "arabic-coffee-beans"
        }

        return "arabic-coffee-beans"
    }

    private static func categoryLabel(productType: String, fallbackKey: String) -> String {
        let trimmedType = productType.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedType.isEmpty, slug(from: trimmedType) != "tea", fallbackKey != "gifts" {
            return trimmedType
        }

        if fallbackKey == "ready-made-drinks" {
            return "Ready-Made Drinks"
        }

        if fallbackKey == "crmb-tallas-speciality-bakery" {
            return "CRMB Talla's Speciality Bakery"
        }

        if fallbackKey == "gifts" {
            return "Talla Boxes"
        }

        if fallbackKey == "other" || fallbackKey == "arabic-coffee-beans" || fallbackKey == "arabic-coffee" {
            return "Arabic & Shamali Coffee"
        }

        return fallbackKey
            .split(separator: "-")
            .map { $0.capitalized }
            .joined(separator: " ")
    }

    private static func slug(from value: String) -> String {
        value
            .lowercased()
            .replacingOccurrences(of: "&", with: "and")
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
    }

    private static func productTag(from tags: [String]) -> String? {
        let preferred = ["BESTSELLER", "NEW", "LOCAL", "PREMIUM", "GIFT"]
        let uppercased = tags.map { $0.uppercased() }
        return preferred.first(where: uppercased.contains)
    }

    private static func formattedPrice(from money: ShopifyProductNode.Money) -> String {
        guard let decimal = Decimal(string: money.amount) else {
            return "\(money.amount) \(money.currencyCode)"
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = money.currencyCode
        formatter.maximumFractionDigits = 3
        formatter.minimumFractionDigits = money.currencyCode == "BHD" ? 3 : 2

        return formatter.string(from: decimal as NSDecimalNumber) ?? "\(money.amount) \(money.currencyCode)"
    }
}

private extension ContentView.BrewingMethod {
    init(article: ShopifyBrewingArticlesResponse.ArticleNode) {
        let summarySource = [article.excerpt, article.content]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? "Brew guide from Shopify."

        self.init(
            id: article.id,
            name: article.title,
            summary: summarySource,
            detail: article.blog.title,
            symbol: Self.symbol(title: article.title, tags: article.tags),
            articleURL: article.onlineStoreUrl ?? Self.articleURL(blogHandle: article.blog.handle, articleHandle: article.handle),
            categories: Self.categories(title: article.title, tags: article.tags),
            difficulty: Self.difficulty(title: article.title, tags: article.tags),
            brewTime: Self.brewTime(title: article.title, tags: article.tags)
        )
    }

    private static func symbol(title: String, tags: [String]) -> String {
        let source = ([title] + tags)
            .joined(separator: " ")
            .lowercased()

        if source.contains("press") {
            return "cup.and.saucer.fill"
        }

        if source.contains("chemex") || source.contains("filter") {
            return "flask.fill"
        }

        if source.contains("espresso") {
            return "bolt.fill"
        }

        if source.contains("cold") {
            return "snowflake"
        }

        return "drop.fill"
    }

    private static func categories(title: String, tags: [String]) -> [String] {
        let cleanedTags = tags
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if !cleanedTags.isEmpty {
            return Array(Set(cleanedTags)).sorted()
        }

        let source = title.lowercased()
        if source.contains("press") {
            return ["Immersion"]
        }

        if source.contains("chemex") || source.contains("pour") {
            return ["Pour Over"]
        }

        if source.contains("espresso") {
            return ["Espresso"]
        }

        if source.contains("cold") {
            return ["Cold Brew"]
        }

        return ["Guide"]
    }

    private static func difficulty(title: String, tags: [String]) -> String {
        let source = ([title] + tags)
            .joined(separator: " ")
            .lowercased()

        if source.contains("espresso") || source.contains("v60") {
            return "Advanced"
        }

        if source.contains("chemex") || source.contains("pour") || source.contains("aeropress") {
            return "Intermediate"
        }

        return "Easy"
    }

    private static func brewTime(title: String, tags: [String]) -> String {
        let source = ([title] + tags)
            .joined(separator: " ")
            .lowercased()

        if source.contains("cold") {
            return "8-12 hr"
        }

        if source.contains("espresso") {
            return "30 sec"
        }

        if source.contains("press") {
            return "4 min"
        }

        if source.contains("chemex") {
            return "4-5 min"
        }

        if source.contains("pour") || source.contains("v60") || source.contains("filter") {
            return "3-4 min"
        }

        return "3-5 min"
    }

    private static func articleURL(blogHandle: String, articleHandle: String) -> URL? {
        URL(string: "https://\(ShopifyConfiguration.shopDomain)/blogs/\(blogHandle)/\(articleHandle)")
    }
}
