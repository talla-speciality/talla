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
        "choose_how_to_pay": ["ar": "اختر طريقة الدفع"],
        "payment_encrypted_secure": ["ar": "عملية الدفع مشفرة وآمنة"],
        "payment_apple_pay_subtitle": ["ar": "دفع سريع وآمن"],
        "payment_apple_pay_guidance": ["ar": "ادفع باستخدام بطاقة محفوظة في Apple Wallet."],
        "payment_benefit_title": ["ar": "بنفت"],
        "payment_benefit_subtitle": ["ar": "لبطاقات الخصم البحرينية"],
        "payment_benefit_sheet_subtitle": ["ar": "لبطاقات الخصم الصادرة من البحرين"],
        "payment_benefit_supporting": ["ar": "استخدم بطاقة الخصم الصادرة من البحرين والرقم السري."],
        "payment_benefit_guidance": ["ar": "اختر هذا الخيار لبطاقة الخصم الصادرة من البحرين."],
        "payment_card_title": ["ar": "بطاقة ائتمان أو خصم"],
        "payment_card_subtitle": ["ar": "فيزا، ماستركارد وأمريكان إكسبريس"],
        "payment_card_supporting": ["ar": "للبطاقات الائتمانية والبطاقات الصادرة من البحرين أو خارجها."],
        "payment_card_guidance": ["ar": "اختر هذا الخيار لبطاقات فيزا أو ماستركارد أو أمريكان إكسبريس."],
        "payment_cash_on_delivery_title": ["ar": "الدفع عند الاستلام"],
        "payment_cash_on_delivery_subtitle": ["ar": "ادفع عند وصول طلبك"],
        "payment_cash_on_delivery_sheet_subtitle": ["ar": "أكمل طلبك عبر صفحة دفع Shopify"],
        "payment_cash_on_delivery_supporting": ["ar": "متاح عندما تكون خدمة تحصيل النقد مدعومة."],
        "payment_cash_on_delivery_guidance": ["ar": "اختر الدفع عند الاستلام في صفحة دفع Shopify قبل تأكيد طلبك."],
        "payment_benefit_action": ["ar": "متابعة إلى بنفت"],
        "payment_card_action": ["ar": "إدخال بيانات البطاقة"],
        "payment_cash_on_delivery_action": ["ar": "المتابعة بالدفع عند الاستلام"],
        "payment_complete_action": ["ar": "إتمام الدفع"],
        "payment_preparing": ["ar": "جارٍ تجهيز الدفع الآمن…"],
        "payment_verifying": ["ar": "جارٍ التحقق من عملية الدفع…"],
        "payment_processing": ["ar": "جارٍ إكمال طلبك…"],
        "payment_complete_title": ["ar": "اكتملت عملية الدفع"],
        "payment_complete_detail": ["ar": "تم تأكيد طلبك من Talla."],
        "payment_cancelled_title": ["ar": "تم إلغاء الدفع"],
        "payment_cancelled_detail": ["ar": "لم يتم خصم أي مبلغ."],
        "payment_failed_title": ["ar": "تعذر إكمال عملية الدفع."],
        "payment_failed_detail": ["ar": "تحقق من بياناتك أو جرّب طريقة دفع أخرى."],
        "payment_terms_reassurance": ["ar": "بالمتابعة، أنت توافق على إجمالي الطلب الموضح أعلاه. لا تحفظ Talla بيانات بطاقتك."],
        "payment_unavailable": ["ar": "غير متاح"],
        "recommended": ["ar": "مقترح"],
        "selected": ["ar": "محدد"],
        "not_selected": ["ar": "غير محدد"],
        "payment_method": ["ar": "طريقة الدفع"],
        "payment_method_change_hint": ["ar": "يفتح خيارات طرق الدفع"],
        "use_payment_method": ["ar": "استخدام %@"],
        "choose_payment_method": ["ar": "اختر طريقة دفع"],
        "language_preference_detail": ["ar": "اختر لغة النصوص واتجاه عرض التطبيق."],
        "welcome_eyebrow": ["ar": "مرحباً بك في Talla"],
        "welcome_title": ["ar": "جهّز حساب Talla مرة واحدة لتطلب أسرع لاحقاً."],
        "welcome_intro": ["ar": "أنشئ حسابك واحفظ بيانات التوصيل الآن حتى تصبح الطلبات وBeans والدفع أسهل لاحقاً."],
        "welcome_account_title": ["ar": "أنشئ حسابك"],
        "welcome_account_detail": ["ar": "استخدم بريداً واحداً للطلب وBeans والطلبات والبيانات المحفوظة."],
        "welcome_delivery_title": ["ar": "احفظ بيانات التوصيل"],
        "welcome_delivery_detail": ["ar": "أضف عنوانك قبل أول طلب حتى لا يتأخر الدفع."],
        "welcome_beans_title": ["ar": "اكسب Beans"],
        "welcome_beans_detail": ["ar": "يمكن ربط الطلبات المكتملة بالمكافآت وسجل الطلبات."],
        "set_up_account": ["ar": "إعداد الحساب"],
        "skip_for_now": ["ar": "تخطي الآن"],
        "onboarding_account_started": ["ar": "أنشئ حسابك أولاً، ثم أضف بيانات التوصيل."],
        "account_created_add_address_toast": ["ar": "تم إنشاء الحساب. أضف بيانات التوصيل الآن."],
        "home_address_label": ["ar": "المنزل"],
        "home": ["ar": "الرئيسية"],
        "shop": ["ar": "المتجر"],
        "brewing": ["ar": "التحضير"],
        "account": ["ar": "الحساب"],
        "appearance": ["ar": "المظهر"],
        "explore": ["ar": "استكشف"],
        "all_products": ["ar": "كل المنتجات"],
        "browse_catalog": ["ar": "تصفح حسب الفئة، واكتشف مفضلات العملاء، وأضف إلى السلة بسهولة."],
        "shop_eyebrow": ["ar": "ماذا تشتهي اليوم؟"],
        "shop_heading": ["ar": "اختر طلبك من Talla"],
        "shop_intro": ["ar": "ابدأ بمشروبات الصيف الباردة، أو خذ أكواباً للطريق، أو أضف حلى، أو جدّد قهوتك المفضلة."],
        "coffee_quiz_title": ["ar": "اكتشف قهوتك من Talla"],
        "coffee_quiz_detail": ["ar": "أجب على ثلاثة أسئلة سريعة لنرشح لك قهوة مناسبة بدون الحاجة لفهم المناطق أو المعالجة أو النكهات."],
        "coffee_quiz_brew_question": ["ar": "كيف تحضر القهوة؟"],
        "coffee_quiz_flavor_question": ["ar": "ما النكهات التي تحبها؟"],
        "coffee_quiz_adventure_question": ["ar": "ما مدى رغبتك بالتجربة؟"],
        "coffee_quiz_match_label": ["ar": "اختيار Talla لك"],
        "coffee_quiz_loading": ["ar": "حمّل المتجر مرة واحدة وسيختار لك Talla قهوة حقيقية."],
        "see_alternatives": ["ar": "بدائل أخرى"],
        "start_brewing": ["ar": "ابدأ التحضير"],
        "brew_now": ["ar": "حضّر الآن"],
        "categories": ["ar": "الفئات"],
        "coffee_concierge_title": ["ar": "مرشد القهوة"],
        "coffee_concierge_detail": ["ar": "اسأل عن تحميصة، هدية، مزاج، ميزانية، أو طريقة تحضير لتحصل على اختيارات Talla المناسبة."],
        "coffee_concierge_placeholder": ["ar": "مثال: هدية أقل من 20 دينار"],
        "concierge_opened": ["ar": "تم فتح مرشد القهوة"],
        "open_drinks": ["ar": "فتح المشروبات"],
        "drinks_opened": ["ar": "تم فتح المشروبات"],
        "concierge_prompt_gift": ["ar": "صندوق هدية"],
        "concierge_prompt_arabic": ["ar": "قهوة عربية"],
        "concierge_prompt_chocolate": ["ar": "مرافقة شوكولاتة"],
        "concierge_prompt_tools": ["ar": "أدوات تحضير"],
        "apple_intelligence_used": ["ar": "Apple Intelligence"],
        "smart_fallback_used": ["ar": "اختيارات ذكية"],
        "add_image": ["ar": "أضف صورة"],
        "change_image": ["ar": "غيّر الصورة"],
        "remove_image": ["ar": "إزالة الصورة"],
        "selected_image": ["ar": "الصورة المختارة"],
        "image_load_failed": ["ar": "تعذر تحميل الصورة"],
        "clear": ["ar": "مسح"],
        "show_everything": ["ar": "عرض الكل"],
        "sort_by": ["ar": "ترتيب حسب"],
        "sort_featured": ["ar": "المميز"],
        "sort_price_low": ["ar": "الأقل سعراً"],
        "sort_price_high": ["ar": "الأعلى سعراً"],
        "sort_available": ["ar": "المتوفر"],
        "search_shop_placeholder": ["ar": "ابحث عن مشروبات الصيف، أكواب، حلى..."],
        "clear_search": ["ar": "مسح البحث"],
        "no_search_results": ["ar": "لا توجد منتجات مطابقة لهذا البحث حالياً."],
        "loading_shop": ["ar": "جاري تحميل المتجر"],
        "no_products": ["ar": "لا توجد منتجات مطابقة لهذه الفئة حالياً."],
        "show_all_products": ["ar": "عرض كل المنتجات"],
        "shop_product_count_one": ["ar": "%d منتج متاح"],
        "shop_product_count_many": ["ar": "%d منتجات متاحة"],
        "shop_search_count_one": ["ar": "%d نتيجة لـ \"%@\""],
        "shop_search_count_many": ["ar": "%d نتائج لـ \"%@\""],
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
        ,"rewards_opened": ["ar": "تم فتح المكافآت"]
        ,"delivery_opened": ["ar": "تم فتح التوصيل"]
        ,"saved_opened": ["ar": "تم فتح المحفوظات"]
        ,"brewing_archive_opened": ["ar": "تم فتح أرشيف التحضير"]
        ,"support_opened": ["ar": "تم فتح الدعم"]
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
        ,"reward_majlis_hosting": ["ar": "مكافأة ضيافة المجلس"]
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
        ,"order_beans_awarded": ["ar": "تمت إضافة %d Beans"]
        ,"order_status_placed": ["ar": "تم الطلب"]
        ,"order_status_confirmed": ["ar": "تم التأكيد"]
        ,"order_status_preparing": ["ar": "قيد التحضير"]
        ,"order_status_ready": ["ar": "جاهز"]
        ,"order_status_completed": ["ar": "مكتمل"]
        ,"order_status_cancelled": ["ar": "ملغي"]
        ,"order_history_opened": ["ar": "تم فتح سجل الطلبات"]
        ,"loading_wallet_pass": ["ar": "جارٍ تحميل بطاقة Wallet..."]
        ,"add_to_apple_wallet": ["ar": "أضف إلى Apple Wallet"]
        ,"your_cart": ["ar": "حقيبتك"]
        ,"saved_carts": ["ar": "الحقائب المحفوظة"]
        ,"saved_carts_empty": ["ar": "احفظ حقيبة ممتلئة وارجع إليها عندما تصبح جاهزاً لإتمام الطلب."]
        ,"shopping_tools": ["ar": "أدوات التسوق"]
        ,"load": ["ar": "تحميل"]
        ,"start_here": ["ar": "ابدأ من هنا"]
        ,"delivery_reminders": ["ar": "التوصيل والتنبيهات"]
        ,"delivery_reminders_subtitle": ["ar": "العناوين، وتنبيهات عودة التوفر، والحقائب المحفوظة لإعادة الطلب بسرعة."]
        ,"settings_help": ["ar": "الإعدادات والمساعدة"]
        ,"settings_help_subtitle": ["ar": "مراجع سريعة وأدوات الحساب عندما تحتاجها."]
        ,"settings_help_short": ["ar": "المساعدة"]
        ,"open_bag": ["ar": "فتح الحقيبة"]
        ,"empty_bag": ["ar": "الحقيبة فارغة"]
        ,"items_in_bag": ["ar": "%d عناصر في الحقيبة"]
        ,"close": ["ar": "إغلاق"]
        ,"shop_bestsellers": ["ar": "تسوق الأكثر طلباً"]
        ,"shop_bestsellers_detail": ["ar": "انتقل مباشرة إلى القهوة والأدوات والهدايا."]
        ,"check_rewards_home": ["ar": "تحقق من المكافآت"]
        ,"check_rewards_home_detail": ["ar": "اعرض Beans والمكافآت وحالة العضوية."]
        ,"membership_tier_format": ["ar": "العضوية: %@"]
        ,"reorder_faster": ["ar": "أعد الطلب أسرع"]
        ,"reorder_faster_detail": ["ar": "افتح الحقائب المحفوظة والعناوين والطلبات الأخيرة."]
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
        ,"privacy_policy": ["ar": "سياسة الخصوصية"]
        ,"privacy_policy_detail": ["ar": "راجع كيف يتعامل Talla مع بيانات الحساب والطلبات والمكافآت والتطبيق."]
        ,"open_policy": ["ar": "فتح السياسة"]
        ,"store_support": ["ar": "دعم المتجر"]
        ,"store_support_detail": ["ar": "افتح صفحة دعم المتجر للمساعدة في الشحن والإرجاع والطلبات."]
        ,"open_support": ["ar": "فتح الدعم"]
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
        ,"delivery_country": ["ar": "دولة التوصيل"]
        ,"country_oman": ["ar": "عمان"]
        ,"country_bahrain": ["ar": "البحرين"]
        ,"country_qatar": ["ar": "قطر"]
        ,"country_kuwait": ["ar": "الكويت"]
        ,"country_uae": ["ar": "الإمارات"]
        ,"country_saudi_arabia": ["ar": "السعودية"]
        ,"notes": ["ar": "ملاحظات"]
        ,"save_address": ["ar": "حفظ العنوان"]
        ,"add_address": ["ar": "أضف عنواناً"]
        ,"no_saved_addresses": ["ar": "لا توجد عناوين محفوظة بعد."]
        ,"preferred": ["ar": "المفضل"]
        ,"saved_brew_recipes": ["ar": "وصفات التحضير المحفوظة"]
        ,"saved_brew_recipes_empty": ["ar": "احفظ نسب القهوة إلى الماء المفضلة من تبويب التحضير وستظهر هنا."]
        ,"open_brewing": ["ar": "افتح التحضير"]
        ,"apply": ["ar": "تطبيق"]
        ,"recently_viewed": ["ar": "شوهد مؤخراً"]
        ,"recently_viewed_empty": ["ar": "المنتجات التي تفتحها أو تحفظها أو تضيفها إلى الحقيبة ستظهر هنا للعودة السريعة."]
        ,"by_chef_ahmad": ["ar": "من الشيف أحمد"]
        ,"cancel": ["ar": "إلغاء"]
        ,"your_bag_is_empty": ["ar": "حقيبتك فارغة."]
        ,"empty_bag_confirmation_title": ["ar": "إفراغ الحقيبة؟"]
        ,"empty_bag_confirmation_message": ["ar": "هل تريد إزالة آخر عنصر من حقيبتك؟"]
        ,"cart_empty_guidance": ["ar": "ابدأ بالقهوة أو الأدوات أو الهدايا. ستظهر اختياراتك هنا قبل إتمام الطلب."]
        ,"preferred_delivery": ["ar": "التوصيل المفضل"]
        ,"edit": ["ar": "تعديل"]
        ,"delivery_address_needed": ["ar": "مطلوب عنوان توصيل"]
        ,"add_preferred_address_before_checkout": ["ar": "أضف عنوانك المفضل قبل إتمام الطلب."]
        ,"how_ordering_works": ["ar": "كيف يعمل الطلب"]
        ,"how_checkout_works": ["ar": "كيف يعمل الدفع"]
        ,"checkout_note_detail": ["ar": "يتم الدفع بأمان عبر Shopify. ارجع إلى Talla بعد ذلك لتتبع طلبك واستلام Beans."]
        ,"ordering_step_review": ["ar": "راجع حقيبتك وبيانات التوصيل."]
        ,"ordering_step_checkout": ["ar": "تابع إلى الدفع الآمن لإرسال الطلب."]
        ,"ordering_step_confirm": ["ar": "تؤكد Talla طلبك وتفاصيل التوصيل."]
        ,"ordering_step_return": ["ar": "ارجع إلى Talla بعد الدفع لعرض حالة الطلب وBeans."]
        ,"ordering_step_beans": ["ar": "تُضاف Beans بعد تسجيل الطلب المكتمل."]
        ,"rewards_voucher": ["ar": "المكافآت والقسائم"]
        ,"rewards_voucher_detail": ["ar": "طبّق مكافأة قبل فتح الدفع، أو تابع بدونها."]
        ,"add_voucher_discount_code": ["ar": "إضافة قسيمة أو رمز خصم"]
        ,"enter_voucher_code": ["ar": "أدخل رمز القسيمة"]
        ,"remove": ["ar": "إزالة"]
        ,"discount_expires": ["ar": "الخصم: %@ • ينتهي %@"]
        ,"your_active_vouchers": ["ar": "قسائمك النشطة"]
        ,"no_active_vouchers": ["ar": "لا توجد قسائم نشطة"]
        ,"active_vouchers_empty": ["ar": "استبدل Beans في Talla Reserve لفتح واحدة."]
        ,"shop_load_failed": ["ar": "تعذر تحميل المتجر."]
        ,"checkout_ready": ["ar": "جاهز للطلب"]
        ,"checkout_readiness_address": ["ar": "أضف عنوان توصيل قبل الدفع لتسهيل إتمام الطلب."]
        ,"checkout_readiness_unavailable": ["ar": "قد لا تكون بعض العناصر متاحة للدفع حالياً."]
        ,"checkout_readiness_voucher": ["ar": "تم تطبيق القسيمة وهي جاهزة للدفع."]
        ,"checkout_readiness_ready": ["ar": "حقيبتك جاهزة. راجع التفاصيل ثم تابع إلى الدفع الآمن."]
        ,"almost_ready": ["ar": "تقريباً جاهز"]
        ,"ready_to_checkout": ["ar": "جاهز للدفع"]
        ,"ready_to_checkout_checked": ["ar": "جاهز للدفع ✓"]
        ,"cart_item_count_singular": ["ar": "%d عنصر"]
        ,"cart_item_count_plural": ["ar": "%d عناصر"]
        ,"address_needed": ["ar": "العنوان مطلوب"]
        ,"delivery_address_needed_short": ["ar": "عنوان التوصيل مطلوب"]
        ,"address_saved": ["ar": "العنوان محفوظ"]
        ,"delivery_address_saved": ["ar": "عنوان التوصيل محفوظ"]
        ,"voucher_applied_summary": ["ar": "تم تطبيق القسيمة %@"]
        ,"add_delivery_address": ["ar": "إضافة عنوان توصيل"]
        ,"items": ["ar": "العناصر"]
        ,"items_ready": ["ar": "%d في الحقيبة • %d جاهزة"]
        ,"voucher_none": ["ar": "لا يوجد تطبيق بعد"]
        ,"order_summary": ["ar": "ملخص الطلب"]
        ,"subtotal": ["ar": "المجموع الفرعي"]
        ,"delivery": ["ar": "التوصيل"]
        ,"calculated_at_checkout": ["ar": "يُحسب عند الدفع"]
        ,"discount": ["ar": "الخصم"]
        ,"none_dash": ["ar": "—"]
        ,"total": ["ar": "الإجمالي"]
        ,"opening_checkout": ["ar": "جارٍ فتح الدفع..."]
        ,"open_checkout": ["ar": "فتح الدفع"]
        ,"add_address_to_continue": ["ar": "أضف العنوان للمتابعة"]
        ,"continue_secure_checkout": ["ar": "الدفع الآمن"]
        ,"secure_checkout_handoff": ["ar": "ادفع بأمان عبر BENEFIT، ثم ارجع إلى Talla لتتبع الطلب وBeans."]
        ,"secure_payment": ["ar": "دفع آمن"]
        ,"payment_methods": ["ar": "طرق الدفع"]
        ,"payment_methods_detail": ["ar": "ادفع عبر BENEFIT باستخدام BenefitPay أو Apple Pay أو البطاقة. لا تحفظ Talla تفاصيل بطاقتك."]
        ,"benefit_pay": ["ar": "BenefitPay"]
        ,"credit_debit_cards": ["ar": "بطاقات الائتمان / الخصم"]
        ,"apple_pay": ["ar": "Apple Pay"]
        ,"shopify_secure_checkout": ["ar": "دفع آمن"]
        ,"available_in_secure_checkout": ["ar": "متاح في الدفع الآمن"]
        ,"unavailable": ["ar": "غير متاح"]
        ,"save_cart": ["ar": "حفظ الحقيبة"]
        ,"save_cart_later": ["ar": "احفظ هذه الحقيبة لوقت لاحق"]
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
        ,"product_added_to_cart": ["ar": "تمت إضافة %@%@ إلى الحقيبة"]
        ,"enter_valid_brew_recipe": ["ar": "أدخل وصفة تحضير صالحة أولاً"]
        ,"brew_recipe_saved_toast": ["ar": "تم حفظ وصفة التحضير"]
        ,"recipe_loaded_toast": ["ar": "تم تحميل %@"]
        ,"brew_recipe_deleted_toast": ["ar": "تم حذف وصفة التحضير"]
        ,"add_items_before_saving_cart": ["ar": "أضف عناصر قبل حفظ الحقيبة"]
        ,"cart_saved_toast": ["ar": "تم حفظ الحقيبة"]
        ,"saved_cart_unavailable": ["ar": "عناصر الحقيبة المحفوظة غير متوفرة حالياً"]
        ,"saved_cart_loaded_toast": ["ar": "تم تحميل %@"]
        ,"saved_cart_deleted_toast": ["ar": "تم حذف الحقيبة المحفوظة"]
        ,"removed_from_favorites": ["ar": "تمت الإزالة من المفضلة"]
        ,"saved_to_favorites": ["ar": "تم الحفظ في المفضلة"]
        ,"removed_from_alerts": ["ar": "تمت الإزالة من التنبيهات"]
        ,"added_to_alerts": ["ar": "تمت الإضافة إلى التنبيهات"]
        ,"notifications_enabled": ["ar": "تم تفعيل الإشعارات"]
        ,"notifications_not_enabled": ["ar": "لم يتم تفعيل الإشعارات"]
        ,"alerts_notifications_enabled_detail": ["ar": "تنبيهات المنتجات وتحديثات الحساب مفعّلة."]
        ,"alerts_notifications_disabled_detail": ["ar": "فعّل الإشعارات لاستلام تذكيرات المنتجات المتابعة وتحديثات الحساب المهمة."]
        ,"alerts_notifications_denied_detail": ["ar": "الإشعارات متوقفة. فعّلها من الإعدادات لاستلام تنبيهات المنتجات."]
        ,"alerts_notifications_unavailable_detail": ["ar": "الإشعارات غير متاحة على هذا الجهاز."]
        ,"enable_notifications": ["ar": "تفعيل"]
        ,"alert_label_back_in_stock": ["ar": "تنبيه عودة التوفر"]
        ,"alert_label_tag_watch": ["ar": "تنبيه %@"]
        ,"alert_label_new_roast": ["ar": "تنبيه تحميصة جديدة"]
        ,"notification_title_watchlist": ["ar": "تذكير متابعة %@"]
        ,"notification_title_roast": ["ar": "تذكير تحميصة %@"]
        ,"notification_body_unavailable": ["ar": "طلبت تنبيهاً عن %@. تحقق من Talla لمعرفة تحديثات التوفر."]
        ,"notification_body_available": ["ar": "ما زلت تفكر في %@؟ التحميصة التي تتابعها بانتظارك في التطبيق."]
        ,"alert_notification_scheduled": ["ar": "تم حفظ التنبيه وجدولة تذكير بالإشعار."]
        ,"added_to_alerts_notifications_off": ["ar": "تم حفظ التنبيه. الإشعارات غير مفعّلة."]
        ,"customer_push_title": ["ar": "إشعارات العملاء"]
        ,"customer_push_detail": ["ar": "تستخدم إشعارات العملاء رموز أجهزة APNs المحفوظة. يمكن للخادم إرسال الحملات إلى كل جهاز منح إذن الإشعارات."]
        ,"items_unavailable_currently": ["ar": "هذه العناصر غير متوفرة حالياً"]
        ,"order_added_to_cart": ["ar": "تمت إضافة الطلب إلى الحقيبة"]
        ,"available_items_added_from_order": ["ar": "تمت إضافة العناصر المتوفرة من ذلك الطلب"]
        ,"sign_in_to_apply_voucher": ["ar": "سجّل الدخول لتطبيق قسيمة المكافآت."]
        ,"enter_voucher_code_first": ["ar": "أدخل رمز القسيمة أولاً."]
        ,"voucher_applied_toast": ["ar": "تم تطبيق القسيمة"]
        ,"cart_no_purchasable_items": ["ar": "لا توجد عناصر قابلة للشراء في حقيبتك."]
        ,"sign_in_before_checkout": ["ar": "سجّل الدخول قبل الدفع."]
        ,"checkout_opened_toast": ["ar": "تم فتح صفحة الدفع. ارجع إلى Talla بعد الدفع."]
        ,"apple_wallet_unavailable": ["ar": "Apple Wallet غير متوفر على هذا الجهاز"]
        ,"sign_in_before_wallet_pass": ["ar": "سجّل الدخول قبل إضافة بطاقتك إلى Wallet"]
        ,"wallet_pass_already_added": ["ar": "بطاقة الولاء موجودة بالفعل في Apple Wallet"]
        ,"daily_surprise_title": ["ar": "اختيار اليوم"]
        ,"daily_surprise_detail": ["ar": "لست متأكداً ماذا تختار؟ دع Talla يفاجئك."]
        ,"surprise_me": ["ar": "فاجئني"]
        ,"surprise_me_refresh": ["ar": "فاجئني ↻"]
        ,"add_pick_to_bag": ["ar": "أضف"]
        ,"see_more": ["ar": "المزيد"]
        ,"surprise_pick_empty": ["ar": "حمّل المتجر مرة واحدة وسيختار Talla شيئاً ممتعاً لك."]
        ,"surprise_pick_ready": ["ar": "اختيار جديد جاهز"]
        ,"tap_cup_reveal_pick": ["ar": "اضغط الكوب لكشف اختيار اليوم"]
        ,"surprise_revealed": ["ar": "تم الكشف"]
        ,"limited_daily_reward": ["ar": "مكافأة يومية محدودة"]
        ,"why_selected": ["ar": "لماذا اخترناه"]
        ,"best_brewing_method": ["ar": "أفضل طريقة تحضير"]
        ,"surprise_reason_floral": ["ar": "يعطي كوباً مشرقاً ومعبراً بطابع زهري ولمسات تشبه التوت."]
        ,"surprise_reason_arabic": ["ar": "يناسب طقس Talla: دافئ، عطري، ومثالي للمشاركة."]
        ,"surprise_reason_comfort": ["ar": "اختيار سهل ومحبوب بطابع حلو ومريح."]
        ,"surprise_reason_gift": ["ar": "اختيار جاهز للمشاركة أو الهدية أو لحظة لطيفة."]
        ,"surprise_reason_default": ["ar": "برز كاختيار يومي مفيد من رف Talla."]
        ,"brew_method_arabic": ["ar": "القهوة العربية"]
        ,"brew_method_espresso": ["ar": "إسبريسو"]
        ,"brew_method_any": ["ar": "استمتع به كما هو"]
        ,"favorites_shelf": ["ar": "رفّك"]
        ,"favorites_shelf_detail": ["ar": "مفضلاتك، وآخر اختياراتك، وكل ما تريد العودة إليه في مكان واحد."]
        ,"open_favorites_shelf": ["ar": "فتح رف المفضلة"]
        ,"favorites_shelf_stand_detail": ["ar": "رف خاص للقهوة والمنتجات التي حفظتها بالقلب."]
        ,"favorites_stand": ["ar": "رف المفضلة"]
        ,"favorites_count": ["ar": "%d اختيارات محفوظة"]
        ,"category_all": ["ar": "الكل"]
        ,"category_summer_drinks": ["ar": "مشروبات الصيف"]
        ,"category_coffee_beans": ["ar": "حبوب القهوة"]
        ,"category_arabic_coffee": ["ar": "القهوة العربية والشمالية"]
        ,"category_drip_bags": ["ar": "أكياس الترشيح"]
        ,"category_equipment": ["ar": "الأدوات"]
        ,"category_cups": ["ar": "الأكواب"]
        ,"category_ready_drinks": ["ar": "المشروبات"]
        ,"category_desserts": ["ar": "CRMB"]
        ,"category_bakery": ["ar": "الحلى"]
        ,"category_spreads": ["ar": "الدهنات"]
        ,"category_hot_chocolate": ["ar": "الشوكولاتة الساخنة"]
        ,"category_gifts": ["ar": "صناديق Talla"]
        ,"category_all_subtitle": ["ar": "كل اختيارات Talla"]
        ,"category_summer_drinks_subtitle": ["ar": "مشروبات باردة موسمية"]
        ,"category_eid_gifts_subtitle": ["ar": "صناديق موسمية"]
        ,"category_coffee_beans_subtitle": ["ar": "حبوب كاملة مختارة"]
        ,"category_arabic_coffee_subtitle": ["ar": "تحميصات تقليدية"]
        ,"category_drip_bags_subtitle": ["ar": "تحضير فردي سريع"]
        ,"category_equipment_subtitle": ["ar": "أدوات التحضير"]
        ,"category_cups_subtitle": ["ar": "أكواب وأدوات للشرب"]
        ,"category_ready_drinks_subtitle": ["ar": "مشروبات جاهزة وأكواب الطريق"]
        ,"category_desserts_subtitle": ["ar": "اختيارات CRMB الحلوة"]
        ,"category_bakery_subtitle": ["ar": "اختيارات CRMB الحلوة"]
        ,"category_spreads_subtitle": ["ar": "مربى وزبدة ومرطبانات"]
        ,"category_hot_chocolate_subtitle": ["ar": "كاكاو وخلطات"]
        ,"category_gifts_subtitle": ["ar": "باقات مختارة"]
        ,"about_talla": ["ar": "عن Talla"]
        ,"about_talla_detail": ["ar": "قهوة مختصة ومكافآت وأساسيات محمصة مصممة حول طقوس القهوة اليومية في البحرين."]
        ,"account_and_settings": ["ar": "الحساب والإعدادات"]
        ,"add": ["ar": "أضف"]
        ,"add_recommended_product": ["ar": "أضف المنتج المقترح"]
        ,"address_remove_failed": ["ar": "تعذر إزالة العنوان حالياً."]
        ,"address_save_failed": ["ar": "تعذر حفظ العنوان حالياً."]
        ,"addresses": ["ar": "العناوين"]
        ,"apple_wallet": ["ar": "Apple Wallet"]
        ,"arabic_card_summary": ["ar": "قهوة عربية"]
        ,"arabic_timer_cue_add": ["ar": "أضف القهوة والبهارات"]
        ,"arabic_timer_cue_heat": ["ar": "سخّن الماء"]
        ,"arabic_timer_cue_settle": ["ar": "اتركها تهدأ"]
        ,"arabic_timer_cue_simmer": ["ar": "اتركها تغلي بهدوء"]
        ,"at": ["ar": "عند"]
        ,"back_in_stock_alerts": ["ar": "تنبيهات عودة التوفر"]
        ,"back_in_stock_reminders": ["ar": "تنبيهات عودة التوفر"]
        ,"back_soon": ["ar": "يعود قريباً"]
        ,"beans": ["ar": "Beans"]
        ,"beans_balance": ["ar": "رصيد Beans"]
        ,"beans_remaining_format": ["ar": "متبقي %d Beans"]
        ,"beans_until_next_reward": ["ar": "%d Beans حتى مكافأتك التالية"]
        ,"beans_update_failed": ["ar": "تعذر تحديث Beans حالياً."]
        ,"best_for_arabic_coffee": ["ar": "الأفضل للقهوة العربية والمشاركة."]
        ,"best_for_cups": ["ar": "الأفضل لتقديم المشروبات الساخنة والباردة."]
        ,"best_for_drip_bags": ["ar": "الأفضل للتحضير السهل أثناء التنقل."]
        ,"best_for_espresso": ["ar": "الأفضل للإسبريسو ومشروبات الحليب."]
        ,"best_for_home_brewing": ["ar": "الأفضل لتجهيز التحضير في المنزل."]
        ,"best_for_iced_v60": ["ar": "الأفضل لـ V60 والقهوة المثلجة."]
        ,"best_for_v60": ["ar": "الأفضل لـ V60 والتحضير بالفلتر."]
        ,"best_ready_to_drink": ["ar": "الأفضل بارداً وجاهزاً للشرب."]
        ,"brew_again": ["ar": "حضّر مرة أخرى"]
        ,"brew_mode_step_bloom": ["ar": "غطّ كل البن واترك القهوة تتفتح."]
        ,"brew_mode_step_finish_pour": ["ar": "استخدم الماء المتبقي واترك التصفية تهدأ."]
        ,"brew_mode_step_grind": ["ar": "سوِّ سطح البن، ابدأ المؤقت، واستعد للتفتح."]
        ,"brew_mode_step_main_pour": ["ar": "اسكب ببطء بحركات دائرية وحافظ على سطح البن متوازناً."]
        ,"brew_mode_step_serve_detail": ["ar": "حرّك، اسكب، واحفظ الوصفة إذا نجح هذا الكوب."]
        ,"brew_mode_step_serve_title": ["ar": "قدّم وتذوّق"]
        ,"brew_paused": ["ar": "متوقف مؤقتاً"]
        ,"brew_ready_message": ["ar": "قهوتك جاهزة. استمتع بها ببطء."]
        ,"brew_time": ["ar": "وقت التحضير"]
        ,"brew_timer": ["ar": "مؤقت التحضير"]
        ,"brew_timer_detail": ["ar": "ابدأ مؤقتاً مركزاً للقهوة التي تحضّرها الآن."]
        ,"brew_timer_done": ["ar": "انتهى مؤقت التحضير"]
        ,"brewing_now": ["ar": "التحضير جارٍ"]
        ,"bronze": ["ar": "برونزي"]
        ,"calculator": ["ar": "الحاسبة"]
        ,"checkout_start_failed": ["ar": "تعذر بدء الدفع حالياً. حقيبتك ما زالت محفوظة."]
        ,"choose_your_strength": ["ar": "اختر قوة القهوة"]
        ,"clear_history": ["ar": "مسح السجل"]
        ,"coffee_card_default_taste": ["ar": "متوازن - حلو - نظيف"]
        ,"coffee_journal_detail": ["ar": "احفظ ما نجح: الطريقة، التقييم، وملاحظة لكوبك القادم."]
        ,"cold_drinks": ["ar": "مشروبات باردة"]
        ,"cold_pick": ["ar": "اختيار بارد"]
        ,"cold_step_add": ["ar": "استخدم طحنة خشنة ومرطباناً أو محضّراً نظيفاً."]
        ,"cold_step_filter": ["ar": "صفِّ التحضير"]
        ,"cold_step_filter_detail": ["ar": "صفِّ بلطف، ثم خفف أو قدّمه فوق الثلج."]
        ,"cold_step_pour": ["ar": "أضف الماء ببطء وتأكد أن كل البن مبلل."]
        ,"cold_step_serve": ["ar": "قدّمه بارداً"]
        ,"cold_step_steep": ["ar": "ابدأ النقع"]
        ,"cold_step_steep_detail": ["ar": "غطّه واتركه بارداً أو بدرجة حرارة الغرفة."]
        ,"cold_timer_cue_filter": ["ar": "صفِّه وقدّمه بارداً"]
        ,"cold_timer_cue_saturate": ["ar": "شبّع البن بالماء"]
        ,"cold_timer_cue_steep": ["ar": "اتركه ينقع ببطء"]
        ,"collapse": ["ar": "إغلاق"]
        ,"connection_issue_try_again": ["ar": "تواجه Talla مشكلة في الاتصال. تحقق من الإنترنت وحاول مرة أخرى."]
        ,"contact_support": ["ar": "تواصل مع الدعم"]
        ,"continue_or_saved_recipes": ["ar": "تابع آخر تحضير"]
        ,"crmb": ["ar": "CRMB"]
        ,"cups_card_summary": ["ar": "كوب قابل لإعادة الاستخدام"]
        ,"current_instruction": ["ar": "التعليمات الحالية"]
        ,"current_target": ["ar": "الهدف الحالي:"]
        ,"current_water_target": ["ar": "هدف الماء الحالي"]
        ,"custom_brew": ["ar": "تحضير مخصص"]
        ,"customer_fallback_name": ["ar": "صديقنا"]
        ,"decrease_quantity": ["ar": "تقليل الكمية"]
        ,"delete_account": ["ar": "حذف الحساب"]
        ,"delete_account_detail": ["ar": "لحذف حساب Talla والبيانات المرتبطة به، تواصل مع الدعم وسنساعدك في إتمام الطلب."]
        ,"delivered": ["ar": "تم التوصيل"]
        ,"delivery_addresses": ["ar": "عناوين التوصيل"]
        ,"device_token_copied": ["ar": "تم نسخ رمز الجهاز"]
        ,"done": ["ar": "تم"]
        ,"end_brew": ["ar": "إنهاء التحضير"]
        ,"end_brew_detail": ["ar": "سيتوقف تقدم المؤقت الحالي."]
        ,"end_brew_question": ["ar": "هل تريد إنهاء هذا التحضير؟"]
        ,"end_session": ["ar": "إنهاء هذه الجلسة"]
        ,"equipment": ["ar": "الأدوات"]
        ,"equipment_card_summary": ["ar": "أدوات تحضير"]
        ,"estimated_delivery_format": ["ar": "التوصيل المتوقع: %@"]
        ,"gift_ready": ["ar": "جاهز كهدية"]
        ,"gifts": ["ar": "الهدايا"]
        ,"gifts_card_summary": ["ar": "صندوق هدايا"]
        ,"guest_account_name": ["ar": "Talla Speciality"]
        ,"guided_brew": ["ar": "تحضير موجه"]
        ,"guided_brew_journal_ready": ["ar": "تم تجهيز ملاحظة المجلة"]
        ,"guided_brew_live_timer": ["ar": "مؤقت تحضير مباشر"]
        ,"guided_brew_mode_detail": ["ar": "اختر طريقة، عدّل القهوة، واتبع كل صبة."]
        ,"hero_subtitle_refined": ["ar": "اكتشف التحميص الطازج وأساسيات التحضير وطقوس القهوة المجزية."]
        ,"hide_passport": ["ar": "إخفاء الجواز"]
        ,"home_recently_viewed_empty": ["ar": "افتح منتجات في المتجر وستظهر هنا."]
        ,"immersion_step_add": ["ar": "استخدم طحنة متوسطة الخشونة وسوِّ سطح البن."]
        ,"immersion_step_finish": ["ar": "اضغط أو صفِّ"]
        ,"immersion_step_finish_detail": ["ar": "تحرك ببطء، ثم اسكب في كوب دافئ."]
        ,"immersion_step_pour": ["ar": "أضف كل الماء، بلّل البن، وحرّك بلطف."]
        ,"immersion_step_steep": ["ar": "اتركه ينقع"]
        ,"immersion_step_steep_detail": ["ar": "اترك الخليط ثابتاً حتى تتطور الحلاوة."]
        ,"increase_quantity": ["ar": "زيادة الكمية"]
        ,"journal": ["ar": "المجلة"]
        ,"journal_deleted_toast": ["ar": "تم حذف ملاحظة القهوة"]
        ,"journal_entries": ["ar": "ملاحظات المجلة"]
        ,"journal_entries_count": ["ar": "%d ملاحظات في المجلة"]
        ,"journal_needs_note": ["ar": "أضف اسم قهوة أو ملاحظة أولاً"]
        ,"journal_saved_toast": ["ar": "تم حفظ ملاحظة القهوة"]
        ,"journal_title": ["ar": "اسم القهوة أو الوصفة"]
        ,"last_ordered_days_ago": ["ar": "آخر طلب قبل %d يوم"]
        ,"latest_order": ["ar": "آخر طلب"]
        ,"light": ["ar": "خفيف"]
        ,"limited": ["ar": "محدود"]
        ,"loved_it": ["ar": "أعجبني"]
        ,"loved_product_prompt": ["ar": "هل أعجبك %@؟"]
        ,"made_with_love_bahrain": ["ar": "صُنع بحب في البحرين"]
        ,"manage_password": ["ar": "إدارة كلمة المرور"]
        ,"method": ["ar": "الطريقة"]
        ,"name_this_recipe": ["ar": "سمِّ هذه الوصفة"]
        ,"new": ["ar": "جديد"]
        ,"next": ["ar": "التالي"]
        ,"next_step": ["ar": "الخطوة التالية"]
        ,"no_orders_short": ["ar": "لا توجد طلبات"]
        ,"not_for_me": ["ar": "ليس مناسباً لي"]
        ,"not_signed_in": ["ar": "غير مسجل الدخول"]
        ,"notifications": ["ar": "الإشعارات"]
        ,"notify_me": ["ar": "نبّهني"]
        ,"notify_when_available": ["ar": "نبّهني عند التوفر"]
        ,"off": ["ar": "إيقاف"]
        ,"on": ["ar": "تشغيل"]
        ,"one_journal_entry": ["ar": "ملاحظة واحدة في المجلة"]
        ,"one_saved_recipe": ["ar": "وصفة محفوظة واحدة"]
        ,"options": ["ar": "خيارات"]
        ,"order_again_detail": ["ar": "منتجات اشتريتها سابقاً."]
        ,"order_again_home": ["ar": "اطلب مرة أخرى"]
        ,"order_number_format": ["ar": "طلب رقم %@"]
        ,"order_status_progress": ["ar": "تقدم حالة الطلب"]
        ,"order_status_received": ["ar": "تم استلام الطلب"]
        ,"order_step_on_the_way": ["ar": "في الطريق"]
        ,"order_step_packed": ["ar": "تم التغليف"]
        ,"order_step_received": ["ar": "تم الاستلام"]
        ,"order_step_resting": ["ar": "مرحلة الراحة"]
        ,"order_step_roasting": ["ar": "التحميص"]
        ,"ordered_today": ["ar": "طُلب اليوم"]
        ,"orders": ["ar": "الطلبات"]
        ,"orders_opened": ["ar": "تم فتح الطلبات"]
        ,"orders_refresh_failed": ["ar": "تعذر تحديث الطلبات حالياً."]
        ,"passport_completed_count": ["ar": "%d من %d مكتمل"]
        ,"passport_origin_stamped": ["ar": "مختوم"]
        ,"passport_origins": ["ar": "مصادر"]
        ,"passport_stamp_mark": ["ar": "مختوم"]
        ,"password_and_security": ["ar": "كلمة المرور والأمان"]
        ,"pause": ["ar": "إيقاف مؤقت"]
        ,"personal_details": ["ar": "البيانات الشخصية"]
        ,"personal_information": ["ar": "المعلومات الشخصية"]
        ,"popular": ["ar": "رائج"]
        ,"pour_timer_cue_bloom": ["ar": "التفتح"]
        ,"pour_timer_cue_bloom_done": ["ar": "اكتمل التفتح"]
        ,"pour_timer_cue_drawdown": ["ar": "يجب أن تبدأ التصفية الآن"]
        ,"pour_timer_cue_finish": ["ar": "اتركه يكتمل"]
        ,"pour_timer_cue_second_pour": ["ar": "ابدأ الصبة الثانية"]
        ,"press_timer_cue_plunge": ["ar": "اضغط ببطء"]
        ,"press_timer_cue_pour": ["ar": "اسكب وبلّل البن"]
        ,"press_timer_cue_steep": ["ar": "اتركه ينقع"]
        ,"product_card_summary_fallback": ["ar": "اختيار من Talla"]
        ,"push_token_local_only": ["ar": "رمز الجهاز محفوظ على هذا الجهاز. سجّل الدخول لمزامنته مع خدمة الإشعارات."]
        ,"push_token_synced": ["ar": "تمت مزامنة رمز الجهاز لـ %@."]
        ,"push_token_waiting": ["ar": "لا يوجد رمز APNs للجهاز بعد. فعّل الإشعارات على جهاز حقيقي لإنشائه."]
        ,"quantity": ["ar": "الكمية"]
        ,"quick_searches": ["ar": "بحث سريع"]
        ,"read_guide": ["ar": "اقرأ الدليل"]
        ,"ready_drink_card_summary": ["ar": "جاهز للشرب"]
        ,"recent_brews": ["ar": "تحضيرات حديثة"]
        ,"recent_notes": ["ar": "ملاحظات حديثة"]
        ,"recent_searches": ["ar": "عمليات بحث حديثة"]
        ,"recently_saved_item": ["ar": "عنصر محفوظ حديثاً"]
        ,"recently_viewed_home_detail": ["ar": "منتجات استكشفتها ولم تشترها."]
        ,"refresh": ["ar": "تحديث"]
        ,"refreshing": ["ar": "جارٍ التحديث..."]
        ,"remove_alert": ["ar": "إزالة التنبيه"]
        ,"reorder": ["ar": "إعادة الطلب"]
        ,"reset_timer": ["ar": "إعادة ضبط المؤقت"]
        ,"restart": ["ar": "إعادة البدء"]
        ,"resume": ["ar": "استئناف"]
        ,"resume_checkout": ["ar": "استئناف الدفع"]
        ,"reward_bag_credit_detail": ["ar": "خصم على كيس قهوة"]
        ,"reward_eligible": ["ar": "مؤهل للمكافأة"]
        ,"reward_espresso_pour_detail": ["ar": "إسبريسو مجاني"]
        ,"reward_gold_reserve_gift_detail": ["ar": "هدية Reserve حصرية"]
        ,"reward_majlis_hosting_detail": ["ar": "خدمة قهوة عربية"]
        ,"reward_pastry_pairing_detail": ["ar": "معجنات مع القهوة"]
        ,"reward_progress": ["ar": "تقدم المكافأة"]
        ,"reward_ready": ["ar": "المكافأة جاهزة"]
        ,"reward_redeem_failed": ["ar": "تعذر استبدال هذه المكافأة حالياً."]
        ,"reward_signature_sip_detail": ["ar": "مشروب مميز واحد"]
        ,"reward_talla_box_treat_detail": ["ar": "رصيد لصندوق هدايا"]
        ,"rewards": ["ar": "المكافآت"]
        ,"rewards_connected": ["ar": "المكافآت متصلة"]
        ,"rewards_refresh_failed": ["ar": "تعذر تحديث المكافآت حالياً."]
        ,"running_low_on_product": ["ar": "هل أوشك %@ على النفاد؟"]
        ,"save_journal_entry": ["ar": "حفظ ملاحظة المجلة"]
        ,"saved_recipes": ["ar": "الوصفات المحفوظة"]
        ,"saved_recipes_count": ["ar": "%d وصفات محفوظة"]
        ,"search": ["ar": "بحث"]
        ,"selected_variant": ["ar": "الخيار:"]
        ,"session": ["ar": "الجلسة"]
        ,"settings_and_help": ["ar": "الإعدادات والمساعدة"]
        ,"settings_help_summary": ["ar": "اللغة، الإشعارات، الدعم"]
        ,"shelf_functional_detail": ["ar": "مفضلاتك، وطلباتك السابقة، واكتشافاتك الحديثة."]
        ,"shelf_sign_in_detail": ["ar": "سجّل الدخول لحفظ المفضلات وإعادة الطلب بسرعة."]
        ,"shelf_signed_out_prompt": ["ar": "سجّل الدخول لحفظ المفضلات وإعادة الطلب بسرعة."]
        ,"shelf_summary_signed_in": ["ar": "مفضلاتك، وطلباتك السابقة، واكتشافاتك الحديثة."]
        ,"shop_product_preview_fallback": ["ar": "اضغط لعرض التفاصيل الكاملة."]
        ,"shop_retry_later": ["ar": "تعذر تحميل المنتجات حالياً. حاول مرة أخرى."]
        ,"sign_in_required": ["ar": "تسجيل الدخول مطلوب"]
        ,"signature_roast_origin_fallback": ["ar": "تحميصة مميزة"]
        ,"similar_order_recommendation_plain": ["ar": "هل أعجبك %@؟ جرّب %@ لمناسبتك القادمة."]
        ,"skip": ["ar": "تخطي"]
        ,"skip_step": ["ar": "تخطي الخطوة"]
        ,"sort": ["ar": "ترتيب"]
        ,"sort_newest": ["ar": "الأحدث"]
        ,"staff_pick": ["ar": "اختيار الفريق"]
        ,"stars": ["ar": "نجوم"]
        ,"start": ["ar": "ابدأ"]
        ,"start_guided_brew": ["ar": "ابدأ تحضيراً موجهاً"]
        ,"start_quiz": ["ar": "ابدأ"]
        ,"strong": ["ar": "قوي"]
        ,"talla_logo": ["ar": "Talla Speciality"]
        ,"talla_passport": ["ar": "جواز Talla"]
        ,"talla_passport_complete_short": ["ar": "اكتمل الجواز. مكافأتك جاهزة في المكافآت."]
        ,"talla_passport_reward_hint_short": ["ar": "أكمل الجواز لفتح مكافأة."]
        ,"talla_tour": ["ar": "جولة Talla"]
        ,"taste_memory_detail": ["ar": "إجابتك تساعد Talla على تحسين التوصيات القادمة."]
        ,"taste_memory_question": ["ar": "كيف كان %@؟"]
        ,"taste_memory_saved": ["ar": "تم حفظ ذائقتك"]
        ,"taste_memory_saved_detail": ["ar": "تم الحفظ. ستستخدم Talla ذلك للتوصيات القادمة."]
        ,"taste_note_balanced": ["ar": "متوازن"]
        ,"taste_note_clean": ["ar": "نظيف"]
        ,"taste_note_sweet": ["ar": "حلو"]
        ,"tasting_notes": ["ar": "ملاحظات التذوق"]
        ,"terms_and_conditions": ["ar": "الشروط والأحكام"]
        ,"this_product": ["ar": "هذا المنتج"]
        ,"timer": ["ar": "المؤقت"]
        ,"tomorrow": ["ar": "غداً"]
        ,"tour_find_talla_detail": ["ar": "اكتشف قهوة من خلال ثلاثة أسئلة سريعة."]
        ,"tour_find_talla_title": ["ar": "اكتشف قهوتك"]
        ,"tour_guided_brew_detail": ["ar": "اتبع كل صبة بأهداف مباشرة ومؤقت مركز."]
        ,"tour_guided_brew_title": ["ar": "تحضير موجه"]
        ,"tour_passport_detail": ["ar": "اجمع المصادر وافتح المكافآت أثناء الاستكشاف."]
        ,"tour_passport_title": ["ar": "جواز Talla"]
        ,"traditional_step_measure": ["ar": "جهّز الدلة والقهوة والبهارات قبل التسخين."]
        ,"traditional_step_serve": ["ar": "قدّمها ببطء"]
        ,"traditional_step_settle": ["ar": "اتركها تهدأ"]
        ,"traditional_step_settle_detail": ["ar": "اتركها قليلاً حتى يكون الصب أنظف."]
        ,"traditional_step_simmer": ["ar": "اغلها بهدوء"]
        ,"traditional_step_simmer_detail": ["ar": "حافظ على حرارة منخفضة حتى تتطور الرائحة."]
        ,"traditional_step_water": ["ar": "سخّن الماء بلطف قبل إضافة القهوة."]
        ,"try_product_gathering": ["ar": "جرّب %@ لمناسبتك القادمة."]
        ,"try_quick_searches": ["ar": "جرّب أحد خيارات البحث السريع أعلاه أو امسح البحث لتصفح الكل."]
        ,"until_next_reward": ["ar": "حتى المكافأة"]
        ,"using": ["ar": "باستخدام"]
        ,"view_all_recent_products": ["ar": "عرض كل المنتجات الحديثة"]
        ,"view_all_saved_products": ["ar": "عرض كل المنتجات المحفوظة"]
        ,"view_passport": ["ar": "عرض الجواز"]
        ,"view_rewards": ["ar": "عرض المكافآت"]
        ,"voucher_apply_failed": ["ar": "تعذر تطبيق هذه القسيمة حالياً."]
        ,"wallet_pass_failed": ["ar": "تعذر تحميل بطاقة Wallet حالياً."]
        ,"welcome_back": ["ar": "مرحباً بعودتك،"]
        ,"welcome_choice_beans": ["ar": "أريد حبوب قهوة"]
        ,"welcome_choice_beans_detail": ["ar": "تصفح الحبوب الكاملة والقهوة العربية."]
        ,"welcome_choice_concierge": ["ar": "ساعدني في الاختيار"]
        ,"welcome_choice_concierge_detail": ["ar": "افتح مرشد القهوة لاختيارات موجهة."]
        ,"welcome_choice_drinks": ["ar": "أريد مشروبات جاهزة"]
        ,"welcome_choice_drinks_detail": ["ar": "اذهب إلى الأكواب والقوارير والصبات اليومية."]
        ,"welcome_choice_gifts": ["ar": "أريد هدايا"]
        ,"welcome_choice_gifts_detail": ["ar": "اعثر على صناديق وهدايا قهوة مدروسة."]
        ,"whatsapp_support": ["ar": "دعم واتساب"]
        ,"your_shelf_empty": ["ar": "سيمتلئ رفك بإعادة الطلب والمنتجات التي شاهدتها مؤخراً. تبقى المفضلات داخل زر الرف."]
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
        "This part of Talla is unavailable right now. Please try again in a moment."
    }

    static func connectionMessage(for serviceName: String) -> String {
        "Talla is having trouble connecting. Check your internet connection and try again."
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
