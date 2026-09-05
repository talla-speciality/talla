module.exports = function createServer(dependencies) {
    const {
        URL,
        accountRecordFromRow,
        accountsStorePath,
        activeCustomerSessionsForEmail,
        activeEventSettings,
        activeVouchersFor,
        addShopifyProductImage,
        addressRowToRecord,
        addressesFor,
        addressesStorePath,
        adminAnalyticsSummary,
        adminAppEmails,
        adminAuditLogsFor,
        adminAuditRowToRecord,
        adminCredentialsConfigured,
        adminCustomerDirectory,
        adminCustomerSummary,
        adminDirectory,
        adminNativePushDevices,
        adminOperationsSummary,
        adminOrderNotificationPayload,
        adminOrderStreamClients,
        adminPassword,
        adminPushDevicesStorePath,
        adminPushSubscriptions,
        adminPushSubscriptionsStorePath,
        adminSessionCookieAttributes,
        adminSessionCookieName,
        adminSessionHours,
        adminSessionSecret,
        adminSessions,
        adminUsername,
        adminUsers,
        alertInboxFor,
        alertInboxRowToRecord,
        alertInboxStorePath,
        alertsStorePath,
        allAccounts,
        allOrdersPayload,
        allPushDevices,
        allTasteMemoryPayload,
        allVouchersFor,
        allowedOrderStatuses,
        allowedTasteMemoryTags,
        announceNewAdminOrder,
        announcedAdminOrderIDs,
        apnsAdminBundleID,
        apnsBearerToken,
        apnsBearerTokenCache,
        apnsBearerTokenExpiresAt,
        apnsBundleID,
        apnsKeyID,
        apnsPrivateKeyBase64,
        apnsPrivateKeyCache,
        apnsPrivateKeyPath,
        apnsTeamID,
        apnsUseSandbox,
        appAttest,
        appAttestStorePath,
        appSettingsStorePath,
        applePaySettlementConfigured,
        applePaySettlementProvider,
        appleSignInClientID,
        appleSigningKeys,
        appleSigningKeysCache,
        appleSigningKeysFetchedAt,
        applyBenefitNotification,
        applyConfirmedMpgsPayment,
        applyRateLimit,
        applyShopifyEazyLocalEffects,
        approvedProductTypes,
        assertShopifyUserErrors,
        authenticateAdmin,
        authenticateCustomer,
        awardOrderBeans,
        awardOrderBeansWithClient,
        base64URLDecode,
        base64URLEncode,
        benefitAPIEndpoint,
        benefitClientPaymentStatus,
        benefitConfigured,
        benefitErrorURL,
        benefitGateway,
        benefitGatewayHostEnvironment,
        benefitNotificationStatus,
        benefitNotificationURL,
        benefitPathMatches,
        benefitPayConfiguration,
        benefitPayConfigured,
        benefitPayQueryErrorDetails,
        benefitPayTransactionIsPending,
        benefitPaymentError,
        benefitPaymentLocks,
        benefitPaymentRowToRecord,
        benefitPaymentsStorePath,
        benefitPublicError,
        benefitResourceKey,
        benefitResultPageHeaders,
        benefitResultState,
        benefitResultURL,
        benefitSuccessURL,
        benefitTranportalID,
        benefitTranportalPassword,
        bhdFils,
        buildCustomerExportCSV,
        buildCustomerTimeline,
        buildPasswordResetLink,
        buildVoucherRecord,
        campaignSettingsStorePath,
        cardPaymentLocks,
        cardPaymentRowToRecord,
        cardPaymentsStorePath,
        clearAdminSessionCookie,
        clientIPAddress,
        completedOrderStatuses,
        config,
        configureWebPush,
        confirmShopifyEazyPayment,
        consumePasswordResetTokenRecord,
        consumeVoucher,
        createAccountRecord,
        createAdminAuditLog,
        createAdminSession,
        createAdminVoucherRecord,
        createBenefitPayCheckStatusSignature,
        createBenefitPayReferenceID,
        createBenefitPendingPayment,
        createCustomerAccessToken,
        createCustomerSession,
        createMpgsTransactionID,
        createPasswordResetToken,
        createPasswordResetTokenRecord,
        createShopifyAdminProduct,
        createShopifyAppOrder,
        crypto,
        csvEscape,
        customerLibraryPayload,
        customerLibraryStorePath,
        customerPhoneForShopifyOrder,
        customerTokenHours,
        customerTokenSecret,
        customerTokensConfigured,
        dataDirectory,
        database,
        decodeBase64URL,
        defaultAppSettings,
        defaultCampaignSettings,
        defaultEventSettings,
        defaultHomeSettings,
        defaultLoyaltyPerks,
        defaultPassportSettings,
        deleteAccountRecord,
        deleteAddress,
        deleteMatchingPendingCheckout,
        deleteShopifyAdminProduct,
        eazyConfiguration,
        eazyPay,
        emailFromAddress,
        emptyCustomerLibrary,
        encodeBase64URL,
        ensureAdminAccess,
        ensureLoyaltyAccount,
        ensureMobileAdminAccess,
        ensurePassSigningFiles,
        ensureShopifyEazyInvoice,
        ensureStoreFile,
        ensureWalletPassRecord,
        escapeHTML,
        escapeShellArgument,
        eventSettingsFromLegacyEid,
        eventsStorePath,
        execFileSync,
        exportCompletedOrderToShopify,
        exportWWDRCertificate,
        finalizeVerifiedShopifyEazyPayment,
        findBenefitPaymentByOrderID,
        findBenefitPaymentByResultToken,
        findBenefitPaymentByTrackID,
        findBenefitPaymentForBrowserReturn,
        findCardPayment,
        findCardPaymentByID,
        findCardPaymentByResultToken,
        findOrderByID,
        findPendingCardPayment,
        findShopifyEazyPayment,
        findShopifyEazyPaymentByGlobalTransactionID,
        findShopifyOrderByExportTag,
        findShopifyOrderExport,
        fs,
        generateVoucherCode,
        generateWalletPass,
        getAccountByAppleUserID,
        getAccountByEmail,
        getAdminSession,
        getAppSettings,
        getBearerToken,
        getCampaignSettings,
        getEventSettings,
        getHomeSettings,
        getLoyaltyAccount,
        getLoyaltyTransactions,
        getPassportSettings,
        googleMobileServices,
        hasPermission,
        hasLoyaltyTransaction,
        hashCustomerToken,
        hashPassword,
        homeSettingsStorePath,
        host,
        http,
        http2,
        isBenefitBrowserReturnPath,
        isEazyPayManualShopifyOrder,
        linkAppleUserIDToAccount,
        listShopifyAdminProducts,
        logRequest,
        loyaltyPayload,
        loyaltyPerksFor,
        loyaltyStorePath,
        loyaltyTransactionIDForOrder,
        managedProductBadgeTags,
        markAdminPushDeviceSent,
        markPushDeviceSent,
        markShopifyOrderAsPaid,
        markWalletPassUpdatedAndNotify,
        maskMpgsSessionID,
        maybeSendOpsAlert,
        memberIDFor,
        mergeCustomerLibraryRecords,
        mpgsConfiguration,
        mpgsGateway,
        mpgsResultIndicatorMatches,
        mpgsSessionResponse,
        mpgsTransactions,
        mutateCustomerLibrary,
        nextProductTags,
        nextRewardText,
        normalizeAPNSEnvironment,
        normalizeAppSettings,
        normalizeBenefitIdentifier,
        normalizeBenefitPayMPQRText,
        normalizeBrewJournalEntry,
        normalizeCampaignSettings,
        normalizeCardPaymentIdentifier,
        normalizeCountryCode,
        normalizeCustomerProductIDs,
        normalizeDeviceToken,
        normalizeEmail,
        normalizeEventSettings,
        normalizeHomeSettings,
        normalizeOrderStatus,
        normalizePassportSettings,
        normalizeShopifyOrderPhone,
        normalizeTallaPaymentID,
        normalizeTasteMemoryInput,
        normalizeTasteMemoryReaction,
        normalizeTasteMemoryTags,
        normalizeTelemetryBatch,
        normalizeTelemetryEvent,
        normalizeWebPushSubscription,
        normalizedBenefitPathname,
        numericOrderTotal,
        opsAlert429Threshold,
        opsAlert5xxThreshold,
        opsAlertCheckIntervalMs,
        opsAlertCooldownMinutes,
        opsAlertStateFor,
        opsAlertTimer,
        opsAlertWebhookURL,
        opsAlertWindowMinutes,
        opsAlertsConfigured,
        orderBeansFor,
        orderCurrency,
        orderPayloadWithRewardState,
        orderRowToRecord,
        orderStatusFromShopifyAdminOrder,
        orderStatusFromShopifyOrder,
        ordersPayload,
        ordersStorePath,
        ordersWithRewardState,
        os,
        parseAdminLogin,
        parseAuthenticatedCustomer,
        parseBenefitCallbackRequest,
        parseCookies,
        passportSettingsStorePath,
        passwordResetEmailConfigured,
        passwordResetTokenHours,
        passwordResetTokenIsValid,
        passwordResetTokensStorePath,
        path,
        persistCardPayment,
        persistShopifyEazyPayment,
        persistShopifyOrderExport,
        persistTelemetryEvent,
        port,
        preferAddressRecords,
        prepareShopifyEazyOrder,
        permissionForAdminRequest,
        previewVoucher,
        processShopifyOrderWebhook,
        productBadgeFromTags,
        profilePayload,
        pruneAdminSessions,
        prunePushDevice,
        pruneRateLimitBuckets,
        publicPaymentURL,
        publicShopifyEazyPayment,
        publishAdminOrderEvent,
        publishShopifyProduct,
        pushDeviceRowToRecord,
        pushDevicesForEmail,
        pushDevicesStorePath,
        queryBenefitPayTransaction,
        queueShopifyOrderExport,
        queueWalletPassUpdate,
        rateLimitBuckets,
        rateLimitMaxRequests,
        rateLimitWindowMs,
        readAPNSPrivateKey,
        readBody,
        readJSON,
        readRawBody,
        recentAdminAuditLogs,
        recordBenefitNotification,
        recordTelemetry,
        registerAdminNativePushDevice,
        registerPushDevice,
        registerWalletPassDevice,
        remotePushConfigured,
        remotePushPayload,
        removeAdminPushSubscription,
        removeStockAlert,
        removeWalletPushDevice,
        renderBenefitResultPage,
        renderClickToPayLaunch,
        renderMpgsResultPage,
        renderPasswordResetPage,
        requestBodyTooLargeError,
        requestLogRowToRecord,
        requestLoggingEnabled,
        requireOperationalPayment,
        resendAPIKey,
        resolveCustomerSession,
        revokeCustomerSession,
        rotateCustomerSession,
        revokeCustomerSessionByID,
        revokeCustomerSessionsForEmail,
        revokeVoucherRecord,
        rewardDetailsFor,
        runOpsAlertChecks,
        runtimeAppSettings,
        safeConfiguredBenefitURL,
        sampleOrderItems,
        sampleOrderTotal,
        sanitizedMpgsSessionStatus,
        saveAddress,
        saveAdminPushSubscription,
        saveAppSettings,
        saveCampaignSettings,
        saveDatabaseBrewJournalEntry,
        saveEventSettings,
        saveHomeSettings,
        savePassportSettings,
        saveTasteMemoryRecord,
        secureStringEqual,
        sendAPNsPushToDevice,
        sendAdminNativeNewOrderPush,
        sendAdminNewOrderPush,
        sendBenefitRedirectAcknowledgement,
        sendCampaignPushToAll,
        sendHTML,
        sendJSON,
        sendOpsAlert,
        sendOrderReadyPush,
        sendOrderReadyPushIfNeeded,
        sendPasswordResetEmail,
        sendRemotePushToDevice,
        sendStockAlertPush,
        sendWalletPassPush,
        setAccountActiveState,
        setPreferredAddress,
        sha256Hex,
        shopifyAdminAPIVersion,
        shopifyAdminAccessToken,
        shopifyAdminConfigured,
        shopifyAdminGraphQLRequest,
        shopifyAdminOrderRecord,
        shopifyAdminProductPayload,
        shopifyAdminPublicationID,
        shopifyAdminShopDomain,
        shopifyEazyPaymentLocks,
        shopifyEazyPaymentRowToRecord,
        shopifyEazyPaymentsStorePath,
        shopifyOrderCreateInput,
        shopifyOrderExportLocks,
        shopifyOrderExportRowToRecord,
        shopifyOrderExportTag,
        shopifyOrderExportsStorePath,
        shopifyOrderPaymentGateways,
        shopifyOrderRecord,
        shopifyOrderTallaPaymentID,
        shopifyWebhookSecret,
        signCustomerTokenPayload,
        signSessionValue,
        startOpsAlertMonitor,
        stockAlertRowToRecord,
        stockAlertStatusFor,
        stockAlertsFor,
        storeVoucherRecord,
        syncLegacyEidCampaignToEvents,
        syncRecentShopifyOrdersForEmail,
        syncStockAlerts,
        synchronizeCoffeeRecords,
        tasteMemoryIDFor,
        tasteMemoryPayload,
        tasteMemoryRowToRecord,
        tasteMemoryStorePath,
        telemetryStorePath,
        tierFor,
        timeSensitiveRemotePushTypes,
        timingSafeStringEqual,
        trimAlertInbox,
        unregisterAdminNativePushDevice,
        unregisterPushDevice,
        unregisterWalletPassDevice,
        updateAccountPasswordRecord,
        updateAccountProfileRecord,
        updateAccountRecord,
        updateBenefitPaymentInitiation,
        updateCardPaymentLifecycle,
        updateCardPaymentSessionVersion,
        updateLoyaltyAccount,
        updateOpsAlertState,
        updateOrderStatusAndAward,
        updateOrderStatusByID,
        updateOrderStatusRecord,
        updateShopifyAdminProduct,
        updateShopifyProductInventory,
        updatedWalletPassesForDevice,
        upsertOrderRecord,
        upsertStockAlert,
        validWalletIdentifier,
        validateBenefitHostedPaymentURL,
        verifyAppleIdentityToken,
        verifyBenefitNotification,
        verifyConfirmedMpgsOrder,
        verifyEazyTransactionForShopifyPayment,
        verifyMpgsAuthenticationForPurchase,
        verifyShopifyWebhook,
        voucherRowToRecord,
        vouchersStorePath,
        wait,
        walletAuthorizationToken,
        walletPassArtworkDirectory,
        walletPassCertificateBase64,
        walletPassCertificatePassword,
        walletPassCertificatePath,
        walletPassRecordBySerial,
        walletPassTemplateDirectory,
        walletPassUpdateTimers,
        walletPassWWDRBase64,
        walletPassWWDRPath,
        walletPassWebServiceURL,
        walletPassesStorePath,
        walletPushCredentialsCache,
        walletPushDevicesForSerial,
        walletPushTLSCredentials,
        webPush,
        webPushConfigured,
        webPushVapidPrivateKey,
        webPushVapidPublicKey,
        webPushVapidSubject,
        withBenefitPaymentLock,
        withCardPaymentLock,
        withShopifyEazyPaymentLock,
        withShopifyOrderExportLock,
        writeDecodedSecret,
        writeJSON,
        writeWalletStampStrips
    } = dependencies;

    return http.createServer(async (request, response) => {
    const startedAt = Date.now();
    response.on("finish", () => {
        void logRequest({
            request,
            statusCode: response.statusCode,
            startedAt,
            accountEmail: request.authenticatedCustomerEmail || null
        });
    });

    if (!request.url) {
        sendJSON(response, 400, { error: "Missing URL" });
        return;
    }

    if (!applyRateLimit(request, response)) {
        return;
    }

    if (request.method === "OPTIONS") {
        sendJSON(response, 204, {});
        return;
    }

    const url = new URL(request.url, `http://${host}:${port}`);

    if (request.method === "POST" && url.pathname === "/telemetry/events") {
        try {
            const body = await readBody(request, 131_072);
            const events = normalizeTelemetryBatch(body);
            if (events.length === 0) {
                sendJSON(response, 400, { error: "No valid telemetry events." });
                return;
            }
            for (const event of events) await persistTelemetryEvent(event, { database, fallbackPath: telemetryStorePath });
            sendJSON(response, 202, { accepted: events.length });
        } catch (error) {
            console.error("Telemetry ingestion failed:", error.code || error.message || "TELEMETRY_FAILED");
            sendJSON(response, 400, { error: "Invalid telemetry payload." });
        }
        return;
    }

    if (request.method === "GET" && url.pathname === "/app-attest/challenge") {
        try {
            const challenge = appAttest.issueChallenge({
                purpose: url.searchParams.get("purpose") || "assertion",
                method: url.searchParams.get("method") || "POST",
                path: url.searchParams.get("path") || ""
            });
            sendJSON(response, 200, { challenge });
        } catch (error) {
            sendJSON(response, 400, { error: error.message || "Unable to issue challenge" });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/app-attest/register") {
        try {
            const body = await readBody(request, 1_000_000);
            if (!body.keyId || !body.challenge || !body.attestationObject) {
                sendJSON(response, 400, { error: "Missing App Attest registration fields" });
                return;
            }
            await appAttest.register(body);
            sendJSON(response, 201, { registered: true });
        } catch (error) {
            sendJSON(response, 401, { error: error.message || "App attestation failed" });
        }
        return;
    }

    let rawProtectedBody = "";
    try {
        rawProtectedBody = appAttest.protectedPaths.has(url.pathname)
            && request.headers["x-talla-play-integrity-token"]
            ? await readRawBody(request)
            : "";
    } catch (error) {
        sendJSON(response, error?.code === "REQUEST_BODY_TOO_LARGE" ? 413 : 400, {
            error: error?.code === "REQUEST_BODY_TOO_LARGE" ? "Request body too large" : "Invalid request body"
        });
        return;
    }
    const appAttestResult = await appAttest.verifyRequest(request, url.pathname, rawProtectedBody);
    if (!appAttestResult.allowed) {
        sendJSON(response, 401, { error: appAttestResult.error || "App Attest verification failed" });
        return;
    }

    const walletPathParts = url.pathname.split("/").filter(Boolean);
    if (walletPathParts[0] === "wallet" && walletPathParts[1] === "v1") {
        try {
            if (request.method === "POST"
                && walletPathParts[2] === "devices"
                && walletPathParts[4] === "registrations"
                && walletPathParts.length === 7) {
                const [, , , deviceLibraryIdentifier, , passTypeIdentifier, serialNumber] = walletPathParts;
                if (![deviceLibraryIdentifier, passTypeIdentifier, serialNumber].every((value) => validWalletIdentifier(value))) {
                    response.writeHead(400).end();
                    return;
                }
                const passRecord = await walletPassRecordBySerial(passTypeIdentifier, serialNumber);
                if (!passRecord || !secureStringEqual(walletAuthorizationToken(request), passRecord.authenticationToken)) {
                    response.writeHead(401).end();
                    return;
                }
                const body = await readBody(request, 16_384);
                const pushToken = normalizeDeviceToken(body.pushToken);
                if (!pushToken) {
                    response.writeHead(400).end();
                    return;
                }
                const created = await registerWalletPassDevice({
                    deviceLibraryIdentifier,
                    pushToken,
                    serialNumber
                });
                response.writeHead(created ? 201 : 200).end();
                return;
            }

            if (request.method === "DELETE"
                && walletPathParts[2] === "devices"
                && walletPathParts[4] === "registrations"
                && walletPathParts.length === 7) {
                const [, , , deviceLibraryIdentifier, , passTypeIdentifier, serialNumber] = walletPathParts;
                if (![deviceLibraryIdentifier, passTypeIdentifier, serialNumber].every((value) => validWalletIdentifier(value))) {
                    response.writeHead(400).end();
                    return;
                }
                const passRecord = await walletPassRecordBySerial(passTypeIdentifier, serialNumber);
                if (!passRecord || !secureStringEqual(walletAuthorizationToken(request), passRecord.authenticationToken)) {
                    response.writeHead(401).end();
                    return;
                }
                await unregisterWalletPassDevice(deviceLibraryIdentifier, serialNumber);
                response.writeHead(200).end();
                return;
            }

            if (request.method === "GET"
                && walletPathParts[2] === "devices"
                && walletPathParts[4] === "registrations"
                && walletPathParts.length === 6) {
                const [, , , deviceLibraryIdentifier, , passTypeIdentifier] = walletPathParts;
                if (![deviceLibraryIdentifier, passTypeIdentifier].every((value) => validWalletIdentifier(value))) {
                    response.writeHead(400).end();
                    return;
                }
                const updated = await updatedWalletPassesForDevice(
                    deviceLibraryIdentifier,
                    passTypeIdentifier,
                    url.searchParams.get("passesUpdatedSince")
                );
                if (updated.serialNumbers.length === 0) {
                    response.writeHead(204).end();
                    return;
                }
                sendJSON(response, 200, {
                    serialNumbers: updated.serialNumbers,
                    lastUpdated: String(updated.lastUpdated)
                }, { "Cache-Control": "no-store" });
                return;
            }

            if (request.method === "GET"
                && walletPathParts[2] === "passes"
                && walletPathParts.length === 5) {
                const [, , , passTypeIdentifier, serialNumber] = walletPathParts;
                if (![passTypeIdentifier, serialNumber].every((value) => validWalletIdentifier(value))) {
                    response.writeHead(400).end();
                    return;
                }
                const passRecord = await walletPassRecordBySerial(passTypeIdentifier, serialNumber);
                if (!passRecord || !secureStringEqual(walletAuthorizationToken(request), passRecord.authenticationToken)) {
                    response.writeHead(401).end();
                    return;
                }
                const generatedPass = await generateWalletPass(passRecord.email);
                response.writeHead(200, {
                    "Content-Type": "application/vnd.apple.pkpass",
                    "Content-Length": fs.statSync(generatedPass.path).size,
                    "Last-Modified": new Date().toUTCString(),
                    "Cache-Control": "no-store"
                });
                const stream = fs.createReadStream(generatedPass.path);
                stream.on("close", () => generatedPass.cleanup());
                stream.on("error", () => generatedPass.cleanup());
                stream.pipe(response);
                return;
            }

            if (request.method === "POST" && walletPathParts[2] === "log" && walletPathParts.length === 3) {
                const body = await readBody(request, 32_768);
                const logCount = Array.isArray(body.logs) ? Math.min(body.logs.length, 50) : 0;
                if (logCount > 0) {
                    console.warn(`Apple Wallet reported ${logCount} pass update log entr${logCount === 1 ? "y" : "ies"}.`);
                }
                response.writeHead(200).end();
                return;
            }
        } catch (error) {
            console.error("Apple Wallet web service request failed:", error.code || error.message || "WALLET_SERVICE_FAILED");
            response.writeHead(error.code === "REQUEST_BODY_TOO_LARGE" ? 413 : 500).end();
            return;
        }
    }

    if (request.method === "GET" && url.pathname === "/health") {
        try {
            if (database.isEnabled()) await database.query("SELECT 1 AS healthy");
            sendJSON(response, 200, { status: "ok", database: database.isEnabled() ? "ok" : "disabled" });
        } catch {
            sendJSON(response, 503, { status: "degraded", database: "unavailable" });
        }
        return;
    }

    if (request.method === "GET" && url.pathname === "/password-reset") {
        sendHTML(response, 200, renderPasswordResetPage(url.searchParams.get("token") || ""));
        return;
    }

    if (request.method === "GET" && (url.pathname === "/admin" || url.pathname === "/admin/")) {
        if (!adminCredentialsConfigured()) {
            sendJSON(response, 503, { error: "Admin credentials are not configured." });
            return;
        }

        const adminPagePath = path.join(adminDirectory, "index.html");
        if (!fs.existsSync(adminPagePath)) {
            sendJSON(response, 404, { error: "Admin dashboard not found." });
            return;
        }

        sendHTML(response, 200, fs.readFileSync(adminPagePath, "utf8"), {
            "Cache-Control": "no-store, no-cache, must-revalidate",
            Pragma: "no-cache",
            Expires: "0"
        });
        return;
    }

    if (request.method === "GET" && ["/admin/manifest.webmanifest", "/admin/sw.js", "/admin/icon.svg"].includes(url.pathname)) {
        const fileName = path.basename(url.pathname);
        const filePath = path.join(adminDirectory, fileName);
        if (!fs.existsSync(filePath)) {
            sendJSON(response, 404, { error: "Admin app asset not found." });
            return;
        }
        const contentTypes = {
            ".webmanifest": "application/manifest+json; charset=utf-8",
            ".js": "application/javascript; charset=utf-8",
            ".svg": "image/svg+xml; charset=utf-8"
        };
        response.writeHead(200, {
            "Content-Type": contentTypes[path.extname(filePath)] || "application/octet-stream",
            "Cache-Control": fileName === "sw.js" ? "no-cache" : "public, max-age=3600"
        });
        response.end(fs.readFileSync(filePath));
        return;
    }

    if (request.method === "GET" && url.pathname === "/campaigns/eid") {
        sendJSON(response, 200, await getCampaignSettings());
        return;
    }

    if (request.method === "GET" && url.pathname === "/app/events") {
        sendJSON(response, 200, activeEventSettings(await getEventSettings()));
        return;
    }

    if (request.method === "GET" && url.pathname === "/app/home-settings") {
        sendJSON(response, 200, await getHomeSettings());
        return;
    }

    if (request.method === "GET" && url.pathname === "/app/passport-settings") {
        sendJSON(response, 200, await getPassportSettings());
        return;
    }

    if (request.method === "GET" && url.pathname === "/app/settings") {
        sendJSON(response, 200, await getAppSettings());
        return;
    }

    if (request.method === "POST" && ["/shopify/webhooks/orders", "/webhooks/shopify/orders-create"].includes(url.pathname)) {
        try {
            const rawBody = await readRawBody(request, 262_144);
            if (!verifyShopifyWebhook(rawBody, request.headers["x-shopify-hmac-sha256"])) {
                sendJSON(response, 401, { error: "Invalid Shopify webhook signature." });
                return;
            }

            const shopifyOrder = JSON.parse(rawBody.toString("utf8"));
            const topic = request.headers["x-shopify-topic"] || "";
            const result = await processShopifyOrderWebhook(shopifyOrder, topic);
            sendJSON(response, 200, result);
            if (result.eazyTallaPaymentId) {
                void ensureShopifyEazyInvoice(result.eazyTallaPaymentId).catch((error) => {
                    console.error(`[PAYMENT_FAILED] payment=${result.eazyTallaPaymentId} stage=invoice_background code=${error.code || error.message || "EAZY_CREATE_FAILED"}`);
                });
            }
        } catch (error) {
            const statusCode = error.code === "REQUEST_BODY_TOO_LARGE" ? 413 : 400;
            sendJSON(response, statusCode, { error: statusCode === 413 ? "Shopify webhook payload is too large." : "Invalid Shopify webhook payload." });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/api/payments/eazy/shopify/session") {
        try {
            const body = await readBody(request, 16_384);
            const authenticated = parseAuthenticatedCustomer(request, response);
            if (!authenticated) return;
            const customer = await resolveCustomerSession(authenticated, response);
            if (!customer) return;
            const tallaPaymentId = normalizeTallaPaymentID(body.tallaPaymentId);
            if (!tallaPaymentId) {
                sendJSON(response, 400, { error: "A valid Talla payment ID is required." });
                return;
            }
            const payment = await withShopifyEazyPaymentLock(tallaPaymentId, async () => {
                const existing = await findShopifyEazyPayment(tallaPaymentId);
                if (existing && existing.email !== normalizeEmail(customer.email)) {
                    throw eazyPay.paymentError("PAYMENT_OWNERSHIP_MISMATCH", 403, "This payment does not belong to the authenticated customer.");
                }
                return existing || persistShopifyEazyPayment({
                    tallaPaymentId,
                    email: customer.email,
                    status: "CREATED",
                    createdAt: new Date().toISOString()
                });
            });
            sendJSON(response, 201, publicShopifyEazyPayment(payment));
        } catch (error) {
            const statusCode = error.code === "REQUEST_BODY_TOO_LARGE" ? 413 : (error.statusCode || 400);
            sendJSON(response, statusCode, { error: statusCode >= 500 ? "Payment setup is temporarily unavailable." : (error.message || "Invalid payment session request.") });
        }
        return;
    }

    if (request.method === "GET" && url.pathname === "/api/payments/eazy/shopify/status") {
        const authenticated = parseAuthenticatedCustomer(request, response);
        if (!authenticated) return;
        const customer = await resolveCustomerSession(authenticated, response);
        if (!customer) return;
        const tallaPaymentId = normalizeTallaPaymentID(url.searchParams.get("tallaPaymentId"));
        if (!tallaPaymentId) {
            sendJSON(response, 400, { error: "A valid Talla payment ID is required." });
            return;
        }
        let payment = await findShopifyEazyPayment(tallaPaymentId);
        if (!payment) {
            sendJSON(response, 404, { error: "Payment was not found." });
            return;
        }
        if (payment.email !== normalizeEmail(customer.email)) {
            sendJSON(response, 403, { error: "This payment does not belong to the authenticated customer." });
            return;
        }
        try {
            if (!payment.eazyPaymentUrl && payment.shopifyOrderId && !["PAID", "CANCELLED"].includes(payment.status)) {
                payment = await ensureShopifyEazyInvoice(tallaPaymentId);
            }
            if (payment.eazyGlobalTransactionId && !["PAID", "CANCELLED"].includes(payment.status)) {
                payment = await confirmShopifyEazyPayment(tallaPaymentId);
            }
        } catch (error) {
            console.error(`[PAYMENT_FAILED] payment=${tallaPaymentId} stage=status_refresh code=${error.code || error.message || "PAYMENT_REFRESH_FAILED"}`);
            payment = await findShopifyEazyPayment(tallaPaymentId);
        }
        sendJSON(response, 200, publicShopifyEazyPayment(payment));
        return;
    }

    if (request.method === "POST" && url.pathname === "/webhooks/eazypay") {
        try {
            const rawBody = await readRawBody(request, 65_536);
            const text = rawBody.toString("utf8");
            let payload;
            if (String(request.headers["content-type"] || "").toLowerCase().includes("application/json")) {
                payload = JSON.parse(text);
            } else {
                payload = Object.fromEntries(new URLSearchParams(text).entries());
            }
            const globalTransactionId = eazyPay.extractGlobalTransactionID(payload);
            if (!globalTransactionId) {
                sendJSON(response, 400, { error: "A valid EazyPay transaction ID is required." });
                return;
            }
            const payment = await findShopifyEazyPaymentByGlobalTransactionID(globalTransactionId);
            if (!payment) {
                sendJSON(response, 400, { error: "Unknown EazyPay transaction." });
                return;
            }
            console.info(`[EAZYPAY_WEBHOOK_RECEIVED] payment=${payment.tallaPaymentId} transaction=${globalTransactionId}`);
            sendJSON(response, 200, { received: true });
            // TODO: Add EazyPay webhook signature verification when EazyPay supplies its header and signing specification.
            // The notification is never trusted as payment proof; confirmation always uses EazyPay's Query API below.
            void confirmShopifyEazyPayment(payment.tallaPaymentId).catch((error) => {
                console.error(`[PAYMENT_FAILED] payment=${payment.tallaPaymentId} stage=eazypay_query code=${error.code || error.message || "EAZY_QUERY_FAILED"}`);
            });
        } catch (error) {
            const statusCode = error.code === "REQUEST_BODY_TOO_LARGE" ? 413 : 400;
            sendJSON(response, statusCode, { error: statusCode === 413 ? "EazyPay webhook payload is too large." : "Malformed EazyPay webhook." });
        }
        return;
    }

    if (request.method === "GET" && url.pathname === "/admin/orders") {
        const admin = await ensureMobileAdminAccess(request, response);
        if (!admin) {
            return;
        }
        if (!hasPermission(admin, "admin:read")) {
            sendJSON(response, 403, { error: "Admin permission required: admin:read." });
            return;
        }

        sendJSON(response, 200, await allOrdersPayload());
        return;
    }

    if (request.method === "POST" && url.pathname === "/admin/orders/status") {
        const admin = await ensureMobileAdminAccess(request, response);
        if (!admin) {
            return;
        }
        if (!hasPermission(admin, "orders:write")) {
            sendJSON(response, 403, { error: "Admin permission required: orders:write." });
            return;
        }

        try {
            const body = await readBody(request);
            const orderID = String(body.orderID || body.id || "").trim();
            const status = normalizeOrderStatus(body.status);

            if (!orderID || !status) {
                sendJSON(response, 400, { error: "Provide an orderID and valid status." });
                return;
            }

            const order = await updateOrderStatusByID(orderID, status);
            if (!order) {
                sendJSON(response, 404, { error: "Order not found." });
                return;
            }

            await createAdminAuditLog({
                adminUser: admin.username,
                action: "mobile_order_status_updated",
                targetEmail: order.email,
                detail: `Updated order ${orderID} to ${status} from the app`,
                metadata: {
                    orderID,
                    status
                }
            });

            const pushResult = await sendOrderReadyPushIfNeeded(status, order);
            sendJSON(response, 200, { orders: await allOrdersPayload(), push: pushResult });
        } catch (error) {
            sendJSON(response, 400, { error: "Invalid order update payload." });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/admin/orders/notify-ready") {
        const admin = await ensureMobileAdminAccess(request, response);
        if (!admin) {
            return;
        }
        if (!hasPermission(admin, "orders:write")) {
            sendJSON(response, 403, { error: "Admin permission required: orders:write." });
            return;
        }

        try {
            const body = await readBody(request);
            const orderID = String(body.orderID || body.id || "").trim();

            if (!orderID) {
                sendJSON(response, 400, { error: "Provide an orderID." });
                return;
            }

            const order = await findOrderByID(orderID);
            if (!order) {
                sendJSON(response, 404, { error: "Order not found." });
                return;
            }

            const pushResult = await sendOrderReadyPush(order.email, order);
            await createAdminAuditLog({
                adminUser: admin.username,
                action: "mobile_order_ready_notification_sent",
                targetEmail: order.email,
                detail: `Sent ready notification for order ${orderID}`,
                metadata: {
                    orderID,
                    configured: pushResult.configured,
                    targetCount: pushResult.targetCount,
                    sentCount: pushResult.sentCount
                }
            });

            sendJSON(response, 200, {
                status: "ok",
                order,
                push: pushResult
            });
        } catch (error) {
            sendJSON(response, 400, { error: "Invalid ready notification payload." });
        }
        return;
    }

    if (url.pathname.startsWith("/admin/api/")) {
        if (request.method === "GET" && url.pathname === "/admin/api/session") {
            if (!adminCredentialsConfigured()) {
                sendJSON(response, 503, { error: "Admin credentials are not configured." });
                return;
            }

            const session = getAdminSession(request);
            if (!session) {
                sendJSON(response, 200, { authenticated: false });
                return;
            }

            sendJSON(response, 200, {
                authenticated: true,
                username: session.username,
                role: session.role,
                permissions: session.permissions,
                expiresAt: new Date(session.expiresAt).toISOString()
            });
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/login") {
            try {
                const body = await readBody(request);
                const credentials = parseAdminLogin(body);
                const principal = authenticateAdmin(adminUsers, credentials.username, credentials.password);
                if (!principal) {
                    sendJSON(response, 401, { error: "Invalid admin credentials." });
                    return;
                }

                const session = createAdminSession(principal);
                sendJSON(response, 200, {
                    authenticated: true,
                    username: session.username,
                    role: session.role,
                    permissions: session.permissions,
                    expiresAt: new Date(session.expiresAt).toISOString()
                }, {
                    "Set-Cookie": session.cookie
                });
            } catch {
                sendJSON(response, 400, { error: "Invalid JSON body." });
            }
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/logout") {
            const session = getAdminSession(request);
            if (session) {
                adminSessions.delete(session.id);
            }

            sendJSON(response, 200, { success: true }, {
                "Set-Cookie": clearAdminSessionCookie()
            });
            return;
        }

        const admin = ensureAdminAccess(request, response);
        if (!admin) {
            return;
        }
        const requiredPermission = permissionForAdminRequest(request.method, url.pathname);
        if (!hasPermission(admin, requiredPermission)) {
            sendJSON(response, 403, { error: `Admin permission required: ${requiredPermission}.` });
            return;
        }

        if (request.method === "GET" && url.pathname === "/admin/api/customer") {
            const email = normalizeEmail(url.searchParams.get("email"));

            if (!email) {
                sendJSON(response, 400, { error: "Missing email." });
                return;
            }

            const summary = await adminCustomerSummary(email);
            if (!summary) {
                sendJSON(response, 404, { error: "Customer not found." });
                return;
            }

            sendJSON(response, 200, summary);
            return;
        }

        if (request.method === "GET" && url.pathname === "/admin/api/customers") {
            sendJSON(response, 200, {
                customers: await adminCustomerDirectory()
            });
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/customers/export") {
            try {
                const body = await readBody(request);
                const emails = Array.isArray(body.emails)
                    ? [...new Set(body.emails.map((entry) => normalizeEmail(entry)).filter(Boolean))]
                    : [];

                if (emails.length === 0) {
                    sendJSON(response, 400, { error: "Provide one or more customer emails to export." });
                    return;
                }

                const directory = await adminCustomerDirectory();
                const customers = directory.filter((customer) => emails.includes(customer.email));
                const csv = buildCustomerExportCSV(customers);
                response.writeHead(200, {
                    "Content-Type": "text/csv; charset=utf-8",
                    "Content-Disposition": `attachment; filename="talla-customers-${new Date().toISOString().slice(0, 10)}.csv"`
                });
                response.end(csv);
            } catch (error) {
                sendJSON(response, 400, { error: "Invalid export payload." });
            }
            return;
        }

        if (request.method === "GET" && url.pathname === "/admin/api/ops/summary") {
            sendJSON(response, 200, await adminOperationsSummary());
            return;
        }

        if (request.method === "GET" && url.pathname === "/admin/api/analytics/summary") {
            sendJSON(response, 200, await adminAnalyticsSummary());
            return;
        }

        if (request.method === "GET" && url.pathname === "/admin/api/audit/recent") {
            const limit = Number(url.searchParams.get("limit")) || 8;
            sendJSON(response, 200, { auditLogs: await recentAdminAuditLogs(limit) });
            return;
        }

        if (request.method === "GET" && url.pathname === "/admin/api/orders") {
            sendJSON(response, 200, { orders: await allOrdersPayload() });
            return;
        }

        if (request.method === "GET" && url.pathname === "/admin/api/orders/stream") {
            response.writeHead(200, {
                "Content-Type": "text/event-stream; charset=utf-8",
                "Cache-Control": "no-cache, no-transform",
                "Connection": "keep-alive",
                "X-Accel-Buffering": "no"
            });
            response.write("retry: 5000\n\n");
            adminOrderStreamClients.add(response);
            const heartbeat = setInterval(() => response.write(": keepalive\n\n"), 25_000);
            heartbeat.unref?.();
            const sessionExpiry = setTimeout(() => response.end(), Math.max(0, new Date(admin.expiresAt).getTime() - Date.now()));
            sessionExpiry.unref?.();
            request.on("close", () => {
                clearInterval(heartbeat);
                clearTimeout(sessionExpiry);
                adminOrderStreamClients.delete(response);
            });
            return;
        }

        if (request.method === "GET" && url.pathname === "/admin/api/notifications/order-push/config") {
            sendJSON(response, 200, {
                configured: webPushConfigured(),
                publicKey: webPushConfigured() ? webPushVapidPublicKey : ""
            });
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/notifications/native/register") {
            try {
                const body = await readBody(request, 16_384);
                const device = await registerAdminNativePushDevice(
                    admin.username,
                    body.deviceToken,
                    body.platform,
                    body.environment
                );
                if (!device) {
                    sendJSON(response, 400, { error: "Invalid native push device token." });
                    return;
                }
                sendJSON(response, 200, { status: "ok", configured: remotePushConfigured(apnsAdminBundleID), device });
            } catch {
                sendJSON(response, 400, { error: "Invalid native push registration." });
            }
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/notifications/native/unregister") {
            try {
                const body = await readBody(request, 16_384);
                const deviceToken = normalizeDeviceToken(body.deviceToken);
                if (!deviceToken) {
                    sendJSON(response, 400, { error: "Invalid native push device token." });
                    return;
                }
                await unregisterAdminNativePushDevice(deviceToken);
                sendJSON(response, 200, { status: "ok" });
            } catch {
                sendJSON(response, 400, { error: "Invalid native push unregister request." });
            }
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/notifications/order-push/subscribe") {
            try {
                if (!configureWebPush()) {
                    sendJSON(response, 503, { error: "Web Push is not configured on the server." });
                    return;
                }
                const body = await readBody(request, 16_384);
                await saveAdminPushSubscription(admin.username, body.subscription);
                sendJSON(response, 201, { subscribed: true });
            } catch {
                sendJSON(response, 400, { error: "Invalid push subscription." });
            }
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/notifications/order-push/unsubscribe") {
            try {
                const body = await readBody(request, 16_384);
                await removeAdminPushSubscription(body.endpoint);
                sendJSON(response, 200, { subscribed: false });
            } catch {
                sendJSON(response, 400, { error: "Invalid unsubscribe request." });
            }
            return;
        }

        if (request.method === "GET" && url.pathname === "/admin/api/taste-memory") {
            sendJSON(response, 200, { tasteMemory: await allTasteMemoryPayload() });
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/orders/status") {
            try {
                const body = await readBody(request);
                const orderID = String(body.orderID || body.id || "").trim();
                const status = normalizeOrderStatus(body.status);

                if (!orderID || !status) {
                    sendJSON(response, 400, { error: "Provide an orderID and valid status." });
                    return;
                }

                const order = await updateOrderStatusByID(orderID, status);
                if (!order) {
                    sendJSON(response, 404, { error: "Order not found." });
                    return;
                }

                await createAdminAuditLog({
                    adminUser: admin.username,
                    action: "order_status_updated",
                    targetEmail: order.email,
                    detail: `Updated order ${orderID} to ${status}`,
                    metadata: {
                        orderID,
                        status
                    }
                });
                const pushResult = await sendOrderReadyPushIfNeeded(status, order);
                sendJSON(response, 200, { order, orders: await allOrdersPayload(), push: pushResult });
            } catch (error) {
                sendJSON(response, 400, { error: "Invalid order update payload." });
            }
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/orders/notify-ready") {
            try {
                const body = await readBody(request);
                const orderID = String(body.orderID || body.id || "").trim();

                if (!orderID) {
                    sendJSON(response, 400, { error: "Provide an orderID." });
                    return;
                }

                const order = await findOrderByID(orderID);
                if (!order) {
                    sendJSON(response, 404, { error: "Order not found." });
                    return;
                }

                const pushResult = await sendOrderReadyPush(order.email, order);
                await createAdminAuditLog({
                    adminUser: admin.username,
                    action: "order_ready_notification_sent",
                    targetEmail: order.email,
                    detail: `Sent ready notification for order ${orderID}`,
                    metadata: {
                        orderID,
                        configured: pushResult.configured,
                        targetCount: pushResult.targetCount,
                        sentCount: pushResult.sentCount
                    }
                });
                sendJSON(response, 200, { order, push: pushResult });
            } catch (error) {
                sendJSON(response, 400, { error: "Invalid ready notification payload." });
            }
            return;
        }

        if (request.method === "GET" && url.pathname === "/admin/api/campaigns/eid") {
            sendJSON(response, 200, await getCampaignSettings());
            return;
        }

        if (request.method === "GET" && url.pathname === "/admin/api/events") {
            sendJSON(response, 200, await getEventSettings());
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/events") {
            try {
                const body = await readBody(request, 262_144);
                if (!Array.isArray(body.events)) {
                    sendJSON(response, 400, { error: "Provide an events array." });
                    return;
                }
                if (body.events.length > 30) {
                    sendJSON(response, 400, { error: "A maximum of 30 events can be stored." });
                    return;
                }

                for (const event of body.events) {
                    const name = String(event?.name || "").trim();
                    const titleEN = String(event?.titleEN || "").trim();
                    if (!name || !titleEN) {
                        sendJSON(response, 400, { error: "Every event needs an internal name and English title." });
                        return;
                    }
                    if (event?.imageURL) {
                        let imageURL;
                        try {
                            imageURL = new URL(String(event.imageURL));
                        } catch {
                            sendJSON(response, 400, { error: `${name} has an invalid banner image URL.` });
                            return;
                        }
                        if (imageURL.protocol !== "https:") {
                            sendJSON(response, 400, { error: `${name} banner images must use HTTPS.` });
                            return;
                        }
                    }
                    const startAt = event?.startAt ? new Date(event.startAt) : null;
                    const endAt = event?.endAt ? new Date(event.endAt) : null;
                    if ((startAt && !Number.isFinite(startAt.getTime())) || (endAt && !Number.isFinite(endAt.getTime()))) {
                        sendJSON(response, 400, { error: `${name} has an invalid start or end date.` });
                        return;
                    }
                    if (startAt && endAt && endAt <= startAt) {
                        sendJSON(response, 400, { error: `${name} must end after it starts.` });
                        return;
                    }
                }

                const settings = await saveEventSettings({ events: body.events });
                await createAdminAuditLog({
                    adminUser: admin.username,
                    action: "events_updated",
                    targetEmail: null,
                    detail: `Saved ${settings.events.length} seasonal event${settings.events.length === 1 ? "" : "s"}`,
                    metadata: {
                        eventIDs: settings.events.map((event) => event.id),
                        enabledEventIDs: settings.events.filter((event) => event.enabled).map((event) => event.id)
                    }
                });
                sendJSON(response, 200, settings);
            } catch (error) {
                sendJSON(response, 400, { error: error.message || "Could not save events." });
            }
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/campaigns/eid") {
            try {
                const body = await readBody(request);
                const eidModeEnabled = Boolean(body.eidModeEnabled);
                const rawEndsAt = body.eidOfferEndsAt ? String(body.eidOfferEndsAt).trim() : "";
                const endsAtDate = rawEndsAt ? new Date(rawEndsAt) : null;

                if (rawEndsAt && !Number.isFinite(endsAtDate.getTime())) {
                    sendJSON(response, 400, { error: "Provide a valid Eid offer end date." });
                    return;
                }

                const settings = await saveCampaignSettings({
                    eidModeEnabled,
                    eidOfferEndsAt: endsAtDate ? endsAtDate.toISOString() : null
                });
                await syncLegacyEidCampaignToEvents(settings);

                await createAdminAuditLog({
                    adminUser: admin.username,
                    action: "eid_campaign_updated",
                    targetEmail: null,
                    detail: `Eid campaign ${settings.eidModeEnabled ? "enabled" : "disabled"}`,
                    metadata: settings
                });

                sendJSON(response, 200, settings);
            } catch (error) {
                sendJSON(response, 400, { error: error.message || "Could not save Eid campaign settings." });
            }
            return;
        }

        if (request.method === "GET" && url.pathname === "/admin/api/app-settings") {
            sendJSON(response, 200, await getAppSettings());
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/app-settings") {
            try {
                const body = await readBody(request);
                const savedSettings = await saveAppSettings(body);
                await createAdminAuditLog({
                    adminUser: admin.username,
                    action: "app_settings_updated",
                    targetEmail: null,
                    detail: "Updated live app controls",
                    metadata: savedSettings
                });
                sendJSON(response, 200, savedSettings);
            } catch (error) {
                sendJSON(response, 400, { error: error.message || "Could not save app settings." });
            }
            return;
        }

        if (request.method === "GET" && url.pathname === "/admin/api/home/signature-roasts") {
            sendJSON(response, 200, await getHomeSettings());
            return;
        }

        if (request.method === "GET" && url.pathname === "/admin/api/passport-settings") {
            sendJSON(response, 200, await getPassportSettings());
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/passport-settings") {
            try {
                const body = await readBody(request);
                const settings = normalizePassportSettings({
                    origins: body.origins,
                    completionRewardTitle: body.completionRewardTitle,
                    completionRewardDetail: body.completionRewardDetail
                });
                const savedSettings = await savePassportSettings(settings);

                await createAdminAuditLog({
                    adminUser: admin.username,
                    action: "passport_settings_updated",
                    targetEmail: null,
                    detail: "Updated Talla Passport settings",
                    metadata: savedSettings
                });

                sendJSON(response, 200, savedSettings);
            } catch (error) {
                sendJSON(response, 400, { error: error.message || "Could not save passport settings." });
            }
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/home/signature-roasts") {
            try {
                const body = await readBody(request);
                if (Array.isArray(body.signatureRoastProductIDs) && body.signatureRoastProductIDs.length > 4) {
                    sendJSON(response, 400, { error: "Choose up to four signature roasts." });
                    return;
                }
                if (Array.isArray(body.quickDrinkProductIDs) && body.quickDrinkProductIDs.length > 6) {
                    sendJSON(response, 400, { error: "Choose up to six Talla Express drinks." });
                    return;
                }

                const quickDrinkProductIDs = Array.isArray(body.quickDrinkProductIDs)
                    ? body.quickDrinkProductIDs.map((productID) => String(productID || "").trim()).filter(Boolean)
                    : [];
                if (quickDrinkProductIDs.length > 0) {
                    const adminProducts = await listShopifyAdminProducts(250);
                    const drinkProductIDs = new Set(
                        adminProducts
                            .filter((product) => ["drinks", "summer drinks"].includes(String(product.productType || "").trim().toLowerCase()))
                            .map((product) => product.id)
                    );
                    if (quickDrinkProductIDs.some((productID) => !drinkProductIDs.has(productID))) {
                        sendJSON(response, 400, { error: "Talla Express can only include products categorized as Drinks or Summer Drinks." });
                        return;
                    }
                }

                const settings = normalizeHomeSettings({
                    signatureRoastProductIDs: body.signatureRoastProductIDs,
                    quickDrinkProductIDs,
                    funPickProductID: body.funPickProductID,
                    heroEyebrow: body.heroEyebrow,
                    heroTitle: body.heroTitle,
                    heroSubtitle: body.heroSubtitle,
                    heroBadge: body.heroBadge,
                    primaryButtonTitle: body.primaryButtonTitle,
                    secondaryButtonTitle: body.secondaryButtonTitle
                });

                const savedSettings = await saveHomeSettings(settings);

                await createAdminAuditLog({
                    adminUser: admin.username,
                    action: "signature_roasts_updated",
                    targetEmail: null,
                    detail: "Updated Home controls and Talla Express drinks",
                    metadata: savedSettings
                });

                sendJSON(response, 200, savedSettings);
            } catch (error) {
                sendJSON(response, 400, { error: error.message || "Could not save signature roasts." });
            }
            return;
        }

        if (request.method === "GET" && url.pathname === "/admin/api/products") {
            if (!shopifyAdminConfigured()) {
                sendJSON(response, 503, { error: "Shopify Admin API is not configured for product control." });
                return;
            }

            const limit = Math.min(Math.max(Number(url.searchParams.get("limit") || 250), 1), 250);
            sendJSON(response, 200, {
                products: await listShopifyAdminProducts(limit),
                publicationConfigured: Boolean(shopifyAdminPublicationID)
            });
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/products") {
            if (!shopifyAdminConfigured()) {
                sendJSON(response, 503, { error: "Shopify Admin API is not configured for product control." });
                return;
            }

            try {
                const body = await readBody(request);
                const title = String(body.title || "").trim();
                const productType = String(body.productType || "").trim();
                const price = Number(body.price);

                if (!title || !productType || !Number.isFinite(price) || price < 0) {
                    sendJSON(response, 400, { error: "Provide a title, category, and valid non-negative price." });
                    return;
                }

                if (!approvedProductTypes.has(productType)) {
                    sendJSON(response, 400, { error: "Choose one of the approved product categories." });
                    return;
                }

                const result = await createShopifyAdminProduct({ title, productType, price });
                await createAdminAuditLog({
                    adminUser: admin.username,
                    action: "product_created",
                    targetEmail: null,
                    detail: `Created product ${title}`,
                    metadata: {
                        productID: result.product?.id || null,
                        title,
                        productType,
                        price,
                        published: result.published
                    }
                });
                sendJSON(response, 200, {
                    product: result.product,
                    publicationConfigured: Boolean(shopifyAdminPublicationID),
                    published: result.published
                });
            } catch (error) {
                if (error.message === "SHOPIFY_ADMIN_NOT_CONFIGURED") {
                    sendJSON(response, 503, { error: "Shopify Admin API is not configured for product control." });
                    return;
                }

                sendJSON(response, 400, { error: error.message || "Could not create product." });
            }
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/products/update") {
            if (!shopifyAdminConfigured()) {
                sendJSON(response, 503, { error: "Shopify Admin API is not configured for product control." });
                return;
            }

            try {
                const body = await readBody(request);
                const productID = String(body.id || "").trim();
                const title = String(body.title || "").trim();
                const productType = body.productType === undefined
                    ? undefined
                    : String(body.productType).trim();
                const descriptionHTML = body.descriptionHTML === undefined
                    ? undefined
                    : String(body.descriptionHTML);
                const status = body.status === undefined
                    ? undefined
                    : String(body.status || "").trim().toUpperCase();
                const badge = body.badge === undefined
                    ? undefined
                    : String(body.badge || "").trim().toUpperCase();
                const existingTags = Array.isArray(body.existingTags) ? body.existingTags : [];
                const tags = badge === undefined ? undefined : nextProductTags(existingTags, badge);
                const defaultVariantID = String(body.defaultVariantID || "").trim() || null;
                const hasPrice = body.price !== undefined && body.price !== null && String(body.price).trim() !== "";
                const price = hasPrice ? Number(body.price) : undefined;

                if (!productID || (!title && !hasPrice && descriptionHTML === undefined && productType === undefined && status === undefined && tags === undefined)) {
                    sendJSON(response, 400, { error: "Provide a product plus a field to update." });
                    return;
                }

                if (status !== undefined && !["ACTIVE", "DRAFT", "ARCHIVED"].includes(status)) {
                    sendJSON(response, 400, { error: "Product status must be Active, Draft, or Archived." });
                    return;
                }

                if (productType !== undefined && !approvedProductTypes.has(productType)) {
                    sendJSON(response, 400, { error: "Choose one of the approved product categories." });
                    return;
                }

                if (hasPrice && (!Number.isFinite(price) || price < 0)) {
                    sendJSON(response, 400, { error: "Price must be a valid non-negative number." });
                    return;
                }

                if (hasPrice && !defaultVariantID) {
                    sendJSON(response, 400, { error: "This product has no default variant available for pricing." });
                    return;
                }

                const product = await updateShopifyAdminProduct({
                    productID,
                    title: title || undefined,
                    productType,
                    descriptionHTML,
                    status,
                    tags,
                    defaultVariantID,
                    price
                });

                await createAdminAuditLog({
                    adminUser: admin.username,
                    action: "product_updated",
                    targetEmail: null,
                    detail: `Updated product ${product.title || productID}`,
                    metadata: {
                        productID,
                        title: title || null,
                        productType: productType === undefined ? null : productType,
                        descriptionUpdated: descriptionHTML !== undefined,
                        status: status || null,
                        badge: badge === undefined ? null : badge,
                        defaultVariantID,
                        price: hasPrice ? price : null
                    }
                });
                sendJSON(response, 200, { product });
            } catch (error) {
                sendJSON(response, 400, { error: error.message || "Could not update product." });
            }
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/products/image") {
            if (!shopifyAdminConfigured()) {
                sendJSON(response, 503, { error: "Shopify Admin API is not configured for product control." });
                return;
            }

            try {
                const body = await readBody(request);
                const productID = String(body.id || "").trim();
                const imageURL = String(body.imageURL || "").trim();
                const altText = String(body.altText || "").trim();

                if (!productID || !imageURL) {
                    sendJSON(response, 400, { error: "Provide a product and image URL." });
                    return;
                }

                const product = await addShopifyProductImage({ productID, imageURL, altText });
                await createAdminAuditLog({
                    adminUser: admin.username,
                    action: "product_image_added",
                    targetEmail: null,
                    detail: `Added image to product ${product.title || productID}`,
                    metadata: {
                        productID,
                        imageURL,
                        altText
                    }
                });
                sendJSON(response, 200, { product });
            } catch (error) {
                sendJSON(response, 400, { error: error.message || "Could not add product image." });
            }
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/products/inventory") {
            if (!shopifyAdminConfigured()) {
                sendJSON(response, 503, { error: "Shopify Admin API is not configured for product control." });
                return;
            }

            try {
                const body = await readBody(request);
                const productID = String(body.id || "").trim();
                const inventoryItemID = String(body.inventoryItemID || "").trim();
                const locationID = String(body.locationID || "").trim();
                const compareQuantity = Number(body.compareQuantity);
                const quantity = Number(body.quantity);

                if (!productID || !inventoryItemID || !locationID || !Number.isFinite(quantity) || quantity < 0) {
                    sendJSON(response, 400, { error: "Provide a product and a valid inventory quantity." });
                    return;
                }

                await updateShopifyProductInventory({
                    inventoryItemID,
                    locationID,
                    quantity,
                    compareQuantity: Number.isFinite(compareQuantity) ? compareQuantity : 0
                });

                const product = (await listShopifyAdminProducts()).find((entry) => entry.id === productID) || null;
                await createAdminAuditLog({
                    adminUser: admin.username,
                    action: "product_inventory_updated",
                    targetEmail: null,
                    detail: `Set inventory for product ${product?.title || productID} to ${quantity}`,
                    metadata: {
                        productID,
                        inventoryItemID,
                        locationID,
                        compareQuantity: Number.isFinite(compareQuantity) ? compareQuantity : 0,
                        quantity
                    }
                });
                sendJSON(response, 200, { product });
            } catch (error) {
                sendJSON(response, 400, { error: error.message || "Could not update inventory." });
            }
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/products/delete") {
            if (!shopifyAdminConfigured()) {
                sendJSON(response, 503, { error: "Shopify Admin API is not configured for product control." });
                return;
            }

            try {
                const body = await readBody(request);
                const productID = String(body.id || "").trim();
                if (!productID) {
                    sendJSON(response, 400, { error: "Missing product id." });
                    return;
                }

                await deleteShopifyAdminProduct(productID);
                await createAdminAuditLog({
                    adminUser: admin.username,
                    action: "product_deleted",
                    targetEmail: null,
                    detail: `Deleted product ${productID}`,
                    metadata: { productID }
                });
                sendJSON(response, 200, { success: true, id: productID });
            } catch (error) {
                sendJSON(response, 400, { error: error.message || "Could not delete product." });
            }
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/customer/update") {
            try {
                const body = await readBody(request);
                const email = normalizeEmail(body.currentEmail || body.email);
                const nextEmail = normalizeEmail(body.nextEmail || body.email);
                const firstName = String(body.firstName || "").trim();
                const lastName = String(body.lastName || "").trim();

                if (!email || !nextEmail || !firstName || !lastName) {
                    sendJSON(response, 400, { error: "Provide an email, first name, and last name." });
                    return;
                }

                const account = await updateAccountRecord(email, { nextEmail, firstName, lastName });
                if (!account) {
                    sendJSON(response, 404, { error: "Customer not found." });
                    return;
                }

                await createAdminAuditLog({
                    adminUser: admin.username,
                    action: "customer_profile_updated",
                    targetEmail: nextEmail,
                    detail: "Updated customer profile from admin",
                    metadata: {
                        previousEmail: email,
                        nextEmail,
                        firstName,
                        lastName
                    }
                });
                sendJSON(response, 200, { profile: profilePayload(account) });
            } catch (error) {
                if (error.message === "ACCOUNT_EMAIL_EXISTS") {
                    sendJSON(response, 409, { error: "That email is already in use." });
                    return;
                }
                sendJSON(response, 400, { error: "Invalid customer profile payload." });
            }
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/customer/send-reset") {
            try {
                const body = await readBody(request);
                const email = normalizeEmail(body.email);

                if (!email) {
                    sendJSON(response, 400, { error: "Provide a customer email." });
                    return;
                }

                if (!passwordResetEmailConfigured()) {
                    sendJSON(response, 503, { error: "Password reset email is not configured." });
                    return;
                }

                const account = await getAccountByEmail(email);
                if (!account) {
                    sendJSON(response, 404, { error: "Customer not found." });
                    return;
                }

                const token = createPasswordResetToken();
                const tokenHash = hashPassword(token);
                const createdAt = new Date().toISOString();
                const expiresAt = new Date(Date.now() + (passwordResetTokenHours * 60 * 60 * 1000)).toISOString();

                await createPasswordResetTokenRecord({
                    email,
                    tokenHash,
                    createdAt,
                    expiresAt
                });
                await sendPasswordResetEmail(email, token);

                await createAdminAuditLog({
                    adminUser: admin.username,
                    action: "password_reset_requested",
                    targetEmail: email,
                    detail: "Sent password reset email from admin",
                    metadata: { expiresAt }
                });

                sendJSON(response, 200, { status: "ok" });
            } catch (error) {
                console.error("Admin password reset request failed.", error);
                sendJSON(response, 500, { error: "Password reset email could not be sent." });
            }
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/customer/deactivate") {
            try {
                const body = await readBody(request);
                const email = normalizeEmail(body.email);
                const nextState = body.isActive === undefined ? false : Boolean(body.isActive);

                if (!email) {
                    sendJSON(response, 400, { error: "Provide a customer email." });
                    return;
                }

                const account = await setAccountActiveState(email, nextState);
                if (!account) {
                    sendJSON(response, 404, { error: "Customer not found." });
                    return;
                }

                if (!nextState) {
                    await revokeCustomerSessionsForEmail(email);
                }

                await createAdminAuditLog({
                    adminUser: admin.username,
                    action: nextState ? "customer_reactivated" : "customer_deactivated",
                    targetEmail: email,
                    detail: nextState ? "Reactivated customer account" : "Deactivated customer account",
                    metadata: { isActive: nextState }
                });

                sendJSON(response, 200, { profile: profilePayload(account) });
            } catch (error) {
                sendJSON(response, 400, { error: "Invalid account state payload." });
            }
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/customer/delete") {
            try {
                const body = await readBody(request);
                const email = normalizeEmail(body.email);

                if (!email) {
                    sendJSON(response, 400, { error: "Provide a customer email." });
                    return;
                }

                await revokeCustomerSessionsForEmail(email);
                const deleted = await deleteAccountRecord(email);
                if (!deleted) {
                    sendJSON(response, 404, { error: "Customer not found." });
                    return;
                }

                await createAdminAuditLog({
                    adminUser: admin.username,
                    action: "customer_deleted",
                    targetEmail: email,
                    detail: "Deleted customer account and related local records",
                    metadata: { email }
                });
                sendJSON(response, 200, { success: true, email });
            } catch (error) {
                sendJSON(response, 400, { error: "Invalid account delete payload." });
            }
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/customer/session/revoke") {
            try {
                const body = await readBody(request);
                const email = normalizeEmail(body.email);
                const sessionID = String(body.sessionID || "").trim();

                if (!email || !sessionID) {
                    sendJSON(response, 400, { error: "Provide a customer email and session id." });
                    return;
                }

                const revoked = await revokeCustomerSessionByID(email, sessionID);
                if (!revoked) {
                    sendJSON(response, 404, { error: "Active session not found." });
                    return;
                }

                await createAdminAuditLog({
                    adminUser: admin.username,
                    action: "customer_session_revoked",
                    targetEmail: email,
                    detail: "Revoked customer session",
                    metadata: { sessionID }
                });

                sendJSON(response, 200, { session: revoked });
            } catch (error) {
                sendJSON(response, 400, { error: "Invalid session revoke payload." });
            }
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/customer/address/save") {
            try {
                const body = await readBody(request);
                const email = normalizeEmail(body.email);
                const label = String(body.label || "").trim();
                const fullName = String(body.fullName || "").trim();
                const phone = String(body.phone || "").trim();
                const line1 = String(body.line1 || "").trim();
                const city = String(body.city || "").trim();
                const countryCode = normalizeCountryCode(body.countryCode, "BH");
                const notes = body.notes ? String(body.notes).trim() : null;
                const addressID = body.addressID ? String(body.addressID).trim() : null;
                const isPreferred = Boolean(body.isPreferred);

                if (!email || !label || !fullName || !phone || !line1 || !city) {
                    sendJSON(response, 400, { error: "Provide a complete address payload." });
                    return;
                }

                const account = await getAccountByEmail(email);
                if (!account) {
                    sendJSON(response, 404, { error: "Customer not found." });
                    return;
                }

                const addresses = await saveAddress(email, {
                    id: addressID,
                    label,
                    fullName,
                    phone,
                    line1,
                    city,
                    countryCode,
                    notes,
                    isPreferred
                });

                await createAdminAuditLog({
                    adminUser: admin.username,
                    action: addressID ? "customer_address_updated" : "customer_address_created",
                    targetEmail: email,
                    detail: addressID ? `Updated address ${label}` : `Created address ${label}`,
                    metadata: {
                        addressID,
                        label,
                        fullName,
                        phone,
                        line1,
                        city,
                        countryCode,
                        hasNotes: Boolean(notes),
                        isPreferred
                    }
                });
                sendJSON(response, 200, { addresses });
            } catch (error) {
                sendJSON(response, 400, { error: "Invalid address payload." });
            }
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/customer/address/delete") {
            try {
                const body = await readBody(request);
                const email = normalizeEmail(body.email);
                const addressID = String(body.addressID || "").trim();

                if (!email || !addressID) {
                    sendJSON(response, 400, { error: "Provide a customer email and address id." });
                    return;
                }

                const account = await getAccountByEmail(email);
                if (!account) {
                    sendJSON(response, 404, { error: "Customer not found." });
                    return;
                }

                const addresses = await deleteAddress(email, addressID);
                await createAdminAuditLog({
                    adminUser: admin.username,
                    action: "customer_address_deleted",
                    targetEmail: email,
                    detail: "Deleted customer address",
                    metadata: { addressID }
                });
                sendJSON(response, 200, { addresses });
            } catch (error) {
                sendJSON(response, 400, { error: "Invalid address delete payload." });
            }
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/orders/update") {
            try {
                const body = await readBody(request);
                const email = normalizeEmail(body.email);
                const orderID = String(body.id || "").trim();
                const status = normalizeOrderStatus(body.status);

                if (!email || !orderID || !status) {
                    sendJSON(response, 400, { error: "Provide an email, order, and valid status." });
                    return;
                }

                const order = await updateOrderStatusAndAward(email, orderID, status);
                if (!order) {
                    sendJSON(response, 404, { error: "Order not found." });
                    return;
                }

                await createAdminAuditLog({
                    adminUser: admin.username,
                    action: "order_status_updated",
                    targetEmail: email,
                    detail: `Updated order ${orderID} to ${status}`,
                    metadata: {
                        orderID,
                        status
                    }
                });
                const pushResult = await sendOrderReadyPushIfNeeded(status, order);
                sendJSON(response, 200, { order, push: pushResult });
            } catch (error) {
                sendJSON(response, 400, { error: "Invalid order update payload." });
            }
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/vouchers/create") {
            try {
                const body = await readBody(request);
                const email = normalizeEmail(body.email);
                const reward = String(body.reward || "").trim();
                const detail = String(body.detail || "").trim();
                const points = Number(body.points);
                const expiresInDays = Number(body.expiresInDays);

                if (!email || !reward || !Number.isFinite(points) || points <= 0 || !Number.isFinite(expiresInDays) || expiresInDays <= 0) {
                    sendJSON(response, 400, { error: "Provide email, reward, positive points, and expiry days." });
                    return;
                }

                const account = await getAccountByEmail(email);
                if (!account) {
                    sendJSON(response, 404, { error: "Customer not found." });
                    return;
                }

                const voucher = await createAdminVoucherRecord({ email, reward, points, detail, expiresInDays });
                await createAdminAuditLog({
                    adminUser: admin.username,
                    action: "voucher_created",
                    targetEmail: email,
                    detail: `Created voucher ${voucher.code}`,
                    metadata: {
                        code: voucher.code,
                        reward,
                        points,
                        expiresInDays
                    }
                });
                sendJSON(response, 200, { voucher });
            } catch (error) {
                sendJSON(response, 400, { error: error.message || "Voucher creation failed." });
            }
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/customers/bulk-voucher") {
            try {
                const body = await readBody(request);
                const emails = Array.isArray(body.emails)
                    ? body.emails.map((entry) => normalizeEmail(entry)).filter(Boolean)
                    : [];
                const reward = String(body.reward || "").trim();
                const detail = String(body.detail || "").trim();
                const points = Number(body.points);
                const expiresInDays = Number(body.expiresInDays);

                if (emails.length === 0 || !reward || !Number.isFinite(points) || points <= 0 || !Number.isFinite(expiresInDays) || expiresInDays <= 0) {
                    sendJSON(response, 400, { error: "Provide customer emails, reward, positive points, and expiry days." });
                    return;
                }

                const uniqueEmails = [...new Set(emails)];
                const created = [];

                for (const email of uniqueEmails) {
                    const account = await getAccountByEmail(email);
                    if (!account) {
                        continue;
                    }

                    const voucher = await createAdminVoucherRecord({ email, reward, points, detail, expiresInDays });
                    created.push({ email, code: voucher.code });

                    await createAdminAuditLog({
                        adminUser: admin.username,
                        action: "bulk_voucher_created",
                        targetEmail: email,
                        detail: `Granted bulk voucher ${voucher.code}`,
                        metadata: {
                            reward,
                            points,
                            expiresInDays
                        }
                    });
                }

                sendJSON(response, 200, {
                    created,
                    requestedCount: uniqueEmails.length,
                    createdCount: created.length
                });
            } catch (error) {
                sendJSON(response, 400, { error: error.message || "Bulk voucher creation failed." });
            }
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/notifications/eid") {
            try {
                const body = await readBody(request);
                const title = String(body.title || "Eid Mubarak from Talla").trim();
                const message = String(body.body || "Eid Gifts and limited rewards are now available in the app.").trim();

                if (!title || !message) {
                    sendJSON(response, 400, { error: "Provide a notification title and message." });
                    return;
                }

                const result = await sendCampaignPushToAll({
                    title,
                    body: message,
                    type: "eid_campaign"
                });

                await createAdminAuditLog({
                    adminUser: admin.username,
                    action: "eid_push_sent",
                    targetEmail: null,
                    detail: `Sent Eid push campaign to ${result.sentCount}/${result.targetCount} devices`,
                    metadata: {
                        title,
                        message,
                        configured: result.configured,
                        targetCount: result.targetCount,
                        sentCount: result.sentCount
                    }
                });

                sendJSON(response, 200, result);
            } catch (error) {
                sendJSON(response, 400, { error: error.message || "Eid push campaign failed." });
            }
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/notifications/push/send-all") {
            try {
                const body = await readBody(request);
                const title = String(body.title || "").trim();
                const message = String(body.body || "").trim();
                const deepLinkURL = String(body.url || "").trim();

                if (!title || !message) {
                    sendJSON(response, 400, { error: "Provide a notification title and message." });
                    return;
                }

                if (title.length > 120 || message.length > 220) {
                    sendJSON(response, 400, { error: "Keep the title under 120 characters and message under 220 characters." });
                    return;
                }

                const result = await sendCampaignPushToAll({
                    title,
                    body: message,
                    type: "customer_campaign",
                    url: deepLinkURL || null
                });

                await createAdminAuditLog({
                    adminUser: admin.username,
                    action: "customer_push_sent",
                    targetEmail: null,
                    detail: `Sent customer push campaign to ${result.sentCount}/${result.targetCount} devices`,
                    metadata: {
                        title,
                        message,
                        url: deepLinkURL || null,
                        configured: result.configured,
                        targetCount: result.targetCount,
                        sentCount: result.sentCount
                    }
                });

                sendJSON(response, 200, result);
            } catch (error) {
                sendJSON(response, 400, { error: error.message || "Customer push campaign failed." });
            }
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/vouchers/revoke") {
            try {
                const body = await readBody(request);
                const code = String(body.code || "").trim();
                if (!code) {
                    sendJSON(response, 400, { error: "Provide a voucher code." });
                    return;
                }

                const voucher = await revokeVoucherRecord(code);
                if (!voucher) {
                    sendJSON(response, 404, { error: "Active voucher not found." });
                    return;
                }

                await createAdminAuditLog({
                    adminUser: admin.username,
                    action: "voucher_revoked",
                    targetEmail: voucher.email,
                    detail: `Revoked voucher ${code}`,
                    metadata: {
                        code,
                        reward: voucher.reward,
                        previousStatus: "active"
                    }
                });
                sendJSON(response, 200, { voucher });
            } catch (error) {
                sendJSON(response, 400, { error: error.message || "Voucher revoke failed." });
            }
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/loyalty/adjust") {
            try {
                const body = await readBody(request);
                const email = normalizeEmail(body.email);
                const points = Number(body.points);
                const note = String(body.note || "Admin adjustment").trim() || "Admin adjustment";

                if (!email || !Number.isFinite(points) || points === 0) {
                    sendJSON(response, 400, { error: "Invalid loyalty adjustment payload." });
                    return;
                }

                const account = await getAccountByEmail(email);
                if (!account) {
                    sendJSON(response, 404, { error: "Customer not found." });
                    return;
                }

                await ensureLoyaltyAccount(email);
                const updated = await updateLoyaltyAccount(email, (loyaltyAccount) => {
                    const nextBalance = loyaltyAccount.pointsBalance + points;
                    if (nextBalance < 0) {
                        throw new Error("INSUFFICIENT_POINTS");
                    }

                    loyaltyAccount.pointsBalance = nextBalance;
                    loyaltyAccount.transactions = loyaltyAccount.transactions || [];
                    loyaltyAccount.transactions.unshift({
                        id: `txn_${Date.now()}`,
                        type: points > 0 ? "earn" : "redeem",
                        points: Math.abs(points),
                        note,
                        createdAt: new Date().toISOString()
                    });
                });

                await createAdminAuditLog({
                    adminUser: admin.username,
                    action: "loyalty_adjustment",
                    targetEmail: email,
                    detail: `${points > 0 ? "Added" : "Removed"} ${Math.abs(points)} Beans`,
                    metadata: {
                        points,
                        note,
                        resultingBalance: updated.pointsBalance
                    }
                });

                sendJSON(response, 200, {
                    profile: profilePayload(account),
                    loyalty: loyaltyPayload(updated)
                });
            } catch (error) {
                if (error.message === "INSUFFICIENT_POINTS") {
                    sendJSON(response, 409, { error: "Adjustment would result in negative Beans." });
                    return;
                }

                sendJSON(response, 400, { error: "Invalid JSON body." });
            }
            return;
        }

        sendJSON(response, 404, { error: "Admin route not found." });
        return;
    }

    if (request.method === "POST" && url.pathname === "/accounts/session/refresh") {
        try {
            const body = await readBody(request, 16_384);
            const session = await rotateCustomerSession(body.refreshToken);
            if (!session) {
                sendJSON(response, 401, { error: "Refresh token is invalid or expired." });
                return;
            }
            sendJSON(response, 200, session);
        } catch (error) {
            const reused = error.code === "REFRESH_TOKEN_REUSED";
            sendJSON(response, 401, {
                error: reused ? "Refresh token reuse detected; sign in again." : "Unable to refresh session."
            });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/accounts/register") {
        try {
            const body = await readBody(request);
            const email = normalizeEmail(body.email);
            const firstName = String(body.firstName || "").trim();
            const lastName = String(body.lastName || "").trim();
            const password = String(body.password || "");

            if (!email || !firstName || !lastName || password.length < 5) {
                sendJSON(response, 400, { error: "Invalid account payload" });
                return;
            }

            const existingAccount = await getAccountByEmail(email);
            if (existingAccount) {
                sendJSON(response, 409, { error: "Account already exists" });
                return;
            }

            const account = {
                id: `acct_${Date.now()}`,
                firstName,
                lastName,
                email,
                passwordHash: hashPassword(password),
                createdAt: new Date().toISOString()
            };

            await createAccountRecord(account);
            await ensureLoyaltyAccount(email);
            const session = await createCustomerSession(email);
            sendJSON(response, 201, {
                profile: profilePayload(account),
                accessToken: session.accessToken,
                expiresAt: session.expiresAt,
                refreshToken: session.refreshToken,
                refreshExpiresAt: session.refreshExpiresAt
            });
        } catch (error) {
            sendJSON(response, 400, { error: "Invalid JSON body" });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/accounts/login") {
        try {
            const body = await readBody(request);
            const email = normalizeEmail(body.email);
            const password = String(body.password || "");

            if (!email || !password) {
                sendJSON(response, 400, { error: "Missing email or password" });
                return;
            }

            const account = await getAccountByEmail(email);

            if (!account || account.passwordHash !== hashPassword(password)) {
                sendJSON(response, 401, { error: "Invalid email or password" });
                return;
            }

            if (account.isActive === false) {
                sendJSON(response, 403, { error: "Account is deactivated" });
                return;
            }

            await ensureLoyaltyAccount(email);
            const session = await createCustomerSession(email);
            sendJSON(response, 200, {
                profile: profilePayload(account),
                accessToken: session.accessToken,
                expiresAt: session.expiresAt,
                refreshToken: session.refreshToken,
                refreshExpiresAt: session.refreshExpiresAt
            });
        } catch (error) {
            sendJSON(response, 400, { error: "Invalid JSON body" });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/accounts/apple") {
        try {
            const body = await readBody(request);
            const identityToken = String(body.identityToken || "");
            const userIdentifier = String(body.userIdentifier || "").trim();
            const nonce = String(body.nonce || "");
            const fallbackEmail = normalizeEmail(body.email);
            const firstName = String(body.firstName || "").trim();
            const lastName = String(body.lastName || "").trim();

            if (!identityToken || !userIdentifier || !nonce) {
                sendJSON(response, 400, { error: "Invalid Apple sign-in payload" });
                return;
            }

            const claims = await verifyAppleIdentityToken(identityToken, nonce);
            if (claims.sub !== userIdentifier) {
                sendJSON(response, 401, { error: "Apple identity mismatch" });
                return;
            }

            const claimedEmail = normalizeEmail(claims.email);
            const email = claimedEmail || fallbackEmail;
            if (!email) {
                sendJSON(response, 400, { error: "Apple sign-in did not return an email address" });
                return;
            }

            let account = await getAccountByAppleUserID(userIdentifier);
            if (!account) {
                account = await getAccountByEmail(email);
                if (account) {
                    account = await linkAppleUserIDToAccount(account.email, userIdentifier);
                }
            }

            const hasProvidedName = Boolean(firstName || lastName);
            const accountUsesApplePlaceholder = account
                && account.firstName === "Apple"
                && account.lastName === "Customer";

            if (account && hasProvidedName && accountUsesApplePlaceholder) {
                account = await updateAccountProfileRecord(
                    account.email,
                    firstName || "",
                    lastName || ""
                );
            }

            if (!account) {
                account = {
                    id: `acct_${Date.now()}`,
                    firstName: firstName || "",
                    lastName: lastName || "",
                    email,
                    passwordHash: hashPassword(`apple:${userIdentifier}:${Date.now()}:${crypto.randomBytes(12).toString("hex")}`),
                    appleUserID: userIdentifier,
                    createdAt: new Date().toISOString()
                };

                await createAccountRecord(account);
            }

            if (account.isActive === false) {
                sendJSON(response, 403, { error: "Account is deactivated" });
                return;
            }

            await ensureLoyaltyAccount(account.email);
            const session = await createCustomerSession(account.email);
            sendJSON(response, 200, {
                profile: profilePayload(account),
                accessToken: session.accessToken,
                expiresAt: session.expiresAt,
                refreshToken: session.refreshToken,
                refreshExpiresAt: session.refreshExpiresAt
            });
        } catch (error) {
            console.error("Apple sign-in failed.", error);
            sendJSON(response, 401, { error: "Apple sign-in could not be verified" });
        }
        return;
    }

    if (request.method === "GET" && url.pathname === "/accounts/session") {
        const authenticated = parseAuthenticatedCustomer(request, response);
        if (!authenticated) {
            return;
        }

        const customer = await resolveCustomerSession(authenticated, response);
        if (!customer) {
            return;
        }

        const account = await getAccountByEmail(customer.email);
        if (!account) {
            sendJSON(response, 404, { error: "Account not found" });
            return;
        }

        sendJSON(response, 200, profilePayload(account));
        return;
    }

    if (request.method === "POST" && url.pathname === "/accounts/logout") {
        const authenticated = parseAuthenticatedCustomer(request, response);
        if (!authenticated) {
            return;
        }

        const customer = await resolveCustomerSession(authenticated, response);
        if (!customer) {
            return;
        }

        await revokeCustomerSession(authenticated.token);
        sendJSON(response, 200, { status: "ok" });
        return;
    }

    if (request.method === "POST" && url.pathname === "/accounts/delete") {
        const authenticated = parseAuthenticatedCustomer(request, response);
        if (!authenticated) {
            return;
        }

        const customer = await resolveCustomerSession(authenticated, response);
        if (!customer) {
            return;
        }

        try {
            // Related customer records use ON DELETE CASCADE in Postgres. The
            // JSON-store implementation performs the equivalent cleanup.
            const deleted = await deleteAccountRecord(customer.email);
            if (!deleted) {
                sendJSON(response, 404, { error: "Account not found" });
                return;
            }

            sendJSON(response, 200, { success: true });
        } catch (error) {
            console.error("Customer account deletion failed.", error);
            sendJSON(response, 500, { error: "The account could not be deleted right now." });
        }
        return;
    }

    if (request.method === "GET" && url.pathname === "/accounts/profile") {
        const requestedEmail = normalizeEmail(url.searchParams.get("email"));
        const authenticated = parseAuthenticatedCustomer(request, response, requestedEmail || null);
        if (!authenticated) {
            return;
        }

        const customer = await resolveCustomerSession(authenticated, response);
        if (!customer) {
            return;
        }

        const account = await getAccountByEmail(customer.email);

        if (!account) {
            sendJSON(response, 404, { error: "Account not found" });
            return;
        }

        sendJSON(response, 200, profilePayload(account));
        return;
    }

    if (request.method === "POST" && url.pathname === "/accounts/profile/update") {
        try {
            const body = await readBody(request);
            const firstName = String(body.firstName || "").trim();
            const lastName = String(body.lastName || "").trim();
            const requestedEmail = normalizeEmail(body.email);
            const authenticated = parseAuthenticatedCustomer(request, response, requestedEmail || null);
            if (!authenticated) {
                return;
            }

            const customer = await resolveCustomerSession(authenticated, response);
            if (!customer) {
                return;
            }

            if (!firstName || !lastName) {
                sendJSON(response, 400, { error: "Invalid profile payload" });
                return;
            }

            const account = await updateAccountProfileRecord(customer.email, firstName, lastName);

            if (!account) {
                sendJSON(response, 404, { error: "Account not found" });
                return;
            }
            sendJSON(response, 200, profilePayload(account));
        } catch (error) {
            sendJSON(response, 400, { error: "Invalid JSON body" });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/accounts/password/request-reset") {
        try {
            const body = await readBody(request);
            const email = normalizeEmail(body.email);

            if (!email) {
                sendJSON(response, 400, { error: "Invalid password reset payload" });
                return;
            }

            if (!passwordResetEmailConfigured()) {
                sendJSON(response, 503, { error: "Password reset email is not configured" });
                return;
            }

            const account = await getAccountByEmail(email);
            if (account) {
                const token = createPasswordResetToken();
                const tokenHash = hashPassword(token);
                const createdAt = new Date().toISOString();
                const expiresAt = new Date(Date.now() + (passwordResetTokenHours * 60 * 60 * 1000)).toISOString();

                await createPasswordResetTokenRecord({
                    email,
                    tokenHash,
                    createdAt,
                    expiresAt
                });
                await sendPasswordResetEmail(email, token);
            }

            sendJSON(response, 200, { status: "ok" });
        } catch (error) {
            console.error("Password reset email request failed.", error);
            sendJSON(response, 500, { error: "Password reset email could not be sent" });
        }
        return;
    }

    if (request.method === "GET" && url.pathname === "/accounts/password/reset-token/validate") {
        const token = String(url.searchParams.get("token") || "");
        if (!token) {
            sendJSON(response, 400, { error: "Missing reset token" });
            return;
        }

        if (await passwordResetTokenIsValid(hashPassword(token))) {
            sendJSON(response, 200, { status: "ok" });
            return;
        }

        sendJSON(response, 410, { error: "This password reset link is invalid or expired" });
        return;
    }

    if (request.method === "POST" && url.pathname === "/accounts/password/complete-reset") {
        try {
            const body = await readBody(request);
            const token = String(body.token || "");
            const newPassword = String(body.newPassword || "");

            if (!token || newPassword.length < 5) {
                sendJSON(response, 400, { error: "Invalid password payload" });
                return;
            }

            const resetRecord = await consumePasswordResetTokenRecord(hashPassword(token));
            if (!resetRecord) {
                sendJSON(response, 410, { error: "This password reset link is invalid or expired" });
                return;
            }

            const account = await updateAccountPasswordRecord(resetRecord.email, hashPassword(newPassword));
            if (!account) {
                sendJSON(response, 404, { error: "Account not found" });
                return;
            }

            await revokeCustomerSessionsForEmail(resetRecord.email);
            sendJSON(response, 200, { status: "ok" });
        } catch (error) {
            sendJSON(response, 400, { error: "Invalid JSON body" });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/accounts/password/reset") {
        try {
            const body = await readBody(request);
            const currentPassword = String(body.currentPassword || "");
            const newPassword = String(body.newPassword || "");
            const requestedEmail = normalizeEmail(body.email);
            const authenticated = parseAuthenticatedCustomer(request, response, requestedEmail || null);
            if (!authenticated) {
                return;
            }

            const customer = await resolveCustomerSession(authenticated, response);
            if (!customer) {
                return;
            }

            if (!currentPassword || newPassword.length < 5) {
                sendJSON(response, 400, { error: "Invalid password payload" });
                return;
            }

            const account = await getAccountByEmail(customer.email);

            if (!account) {
                sendJSON(response, 404, { error: "Account not found" });
                return;
            }

            if (account.passwordHash !== hashPassword(currentPassword)) {
                sendJSON(response, 401, { error: "Current password is incorrect" });
                return;
            }

            await updateAccountPasswordRecord(customer.email, hashPassword(newPassword));
            await revokeCustomerSessionsForEmail(customer.email);
            sendJSON(response, 200, { status: "ok" });
        } catch (error) {
            sendJSON(response, 400, { error: "Invalid JSON body" });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/accounts/password/change") {
        try {
            const body = await readBody(request);
            const email = normalizeEmail(body.email);
            const currentPassword = String(body.currentPassword || "");
            const newPassword = String(body.newPassword || "");

            if (!email || !currentPassword || newPassword.length < 5) {
                sendJSON(response, 400, { error: "Invalid password payload" });
                return;
            }

            const account = await getAccountByEmail(email);

            if (!account) {
                sendJSON(response, 404, { error: "Account not found" });
                return;
            }

            if (account.passwordHash !== hashPassword(currentPassword)) {
                sendJSON(response, 401, { error: "Current password is incorrect" });
                return;
            }

            await updateAccountPasswordRecord(email, hashPassword(newPassword));
            await revokeCustomerSessionsForEmail(email);
            sendJSON(response, 200, { status: "ok" });
        } catch (error) {
            sendJSON(response, 400, { error: "Invalid JSON body" });
        }
        return;
    }

    if (request.method === "GET" && url.pathname === "/loyalty/account") {
        const requestedEmail = normalizeEmail(url.searchParams.get("email"));
        const authenticated = parseAuthenticatedCustomer(request, response, requestedEmail || null);
        if (!authenticated) {
            return;
        }

        const customer = await resolveCustomerSession(authenticated, response);
        if (!customer) {
            return;
        }

        const customerAccount = await getAccountByEmail(customer.email);
        if (!customerAccount) {
            sendJSON(response, 404, { error: "Account not found" });
            return;
        }

        const account = await ensureLoyaltyAccount(customer.email);
        sendJSON(response, 200, loyaltyPayload(account));
        return;
    }

    if (request.method === "POST" && url.pathname === "/api/payments/apple-pay/session") {
        if (!await requireOperationalPayment("applePayEnabled", response)) return;
        let body;
        try {
            body = await readBody(request, 16_384);
        } catch (error) {
            const publicError = mpgsGateway.normalizeMpgsError(error);
            sendJSON(response, publicError.statusCode === 413 ? 413 : 400, { error: publicError.message });
            return;
        }
        const authenticated = parseAuthenticatedCustomer(request, response);
        if (!authenticated) return;
        const customer = await resolveCustomerSession(authenticated, response);
        if (!customer) return;
        const localOrderID = normalizeCardPaymentIdentifier(body.orderID || body.orderId || body.localOrderId);
        if (!localOrderID) {
            sendJSON(response, 400, { error: "Provide a valid existing orderID." });
            return;
        }
        try {
            const result = await withCardPaymentLock(`${customer.email}:${localOrderID}`, async () => {
                const order = await findOrderByID(localOrderID);
                const existingPayment = await findPendingCardPayment(localOrderID, customer.email);
                if (existingPayment && existingPayment.paymentMethod !== "APPLE_PAY") {
                    throw benefitPaymentError("MPGS_PAYMENT_METHOD_CONFLICT", 409, "Another payment method is already pending for this order.");
                }
                return mpgsGateway.initializeMpgsPayment({
                    configuration: mpgsConfiguration,
                    order,
                    customerEmail: customer.email,
                    existingPayment,
                    paymentMethod: "APPLE_PAY",
                    persistPayment: persistCardPayment
                });
            });
            console.info(`MPGS Apple Pay session prepared: ${maskMpgsSessionID(result.payment.sessionID)}.`);
            sendJSON(response, 200, mpgsSessionResponse(result.payment));
        } catch (error) {
            console.error("MPGS Apple Pay session creation failed:", error.code || "MPGS_APPLE_SESSION_FAILED");
            const publicError = mpgsGateway.normalizeMpgsError(error);
            sendJSON(response, publicError.statusCode, { error: publicError.message });
        }
        return;
    }

    if (request.method === "POST" && [
        "/api/payments/apple-pay/authorize",
        "/payments/apple-pay/authorize"
    ].includes(url.pathname)) {
        let body;
        let paymentForFailure = null;
        try {
            body = await readBody(request, 16_384);
        } catch (error) {
            const publicError = mpgsGateway.normalizeMpgsError(error);
            sendJSON(response, publicError.statusCode === 413 ? 413 : 400, { error: publicError.message });
            return;
        }
        const authenticated = parseAuthenticatedCustomer(request, response);
        if (!authenticated) return;
        const customer = await resolveCustomerSession(authenticated, response);
        if (!customer) return;
        if (body.paymentTokenData || body.paymentData || body.token) {
            sendJSON(response, 400, { error: "Apple Pay tokens must be stored in the Mastercard SDK session, not sent to Talla." });
            return;
        }
        const localOrderID = normalizeCardPaymentIdentifier(body.localOrderId || body.orderID || body.orderId);
        const sessionID = normalizeCardPaymentIdentifier(body.sessionId, 100);
        if (!localOrderID || !sessionID) {
            sendJSON(response, 400, { error: "Provide a valid orderID and SDK-created sessionId." });
            return;
        }
        try {
            const payment = await findCardPayment(localOrderID, customer.email);
            paymentForFailure = payment;
            const order = payment ? await findOrderByID(payment.localOrderID) : null;
            mpgsGateway.verifyMpgsOrderPayment(payment, order, customer.email);
            if (payment.paymentMethod !== "APPLE_PAY" || !timingSafeStringEqual(sessionID, payment.sessionID)) {
                throw benefitPaymentError("MPGS_SESSION_MISMATCH", 409, "Apple Pay session does not match this order.");
            }
            if (payment.effectsAppliedAt) {
                sendJSON(response, 200, { status: "succeeded", orderId: payment.mpgsOrderID, duplicate: true });
                return;
            }
            const purchaseTransactionID = payment.purchaseTransactionID || createMpgsTransactionID("APAY");
            await updateCardPaymentLifecycle(payment.paymentID, { purchaseTransactionID, status: "Processing" });
            const purchaseResponse = await mpgsGateway.executeMpgsPurchase(mpgsConfiguration, {
                orderId: payment.mpgsOrderID,
                transactionId: purchaseTransactionID,
                sessionId: payment.sessionID,
                amount: payment.amount,
                walletProvider: "APPLE_PAY"
            });
            mpgsGateway.assertMpgsPaymentAccepted(purchaseResponse);
            const gatewayOrder = await mpgsGateway.retrieveMpgsOrder(mpgsConfiguration, payment.mpgsOrderID);
            const applied = await applyConfirmedMpgsPayment(payment.paymentID, gatewayOrder);
            console.info(`MPGS Apple Pay confirmed for order ${localOrderID}: applied=${applied.applied}.`);
            sendJSON(response, 200, { status: "succeeded", orderId: payment.mpgsOrderID, duplicate: !applied.applied });
        } catch (error) {
            if (paymentForFailure && Number(error.statusCode) === 402) {
                try {
                    await updateCardPaymentLifecycle(paymentForFailure.paymentID, { status: "Declined" });
                } catch (storageError) {
                    console.error("MPGS Apple Pay decline could not be recorded:", storageError.code || "MPGS_STORAGE_FAILED");
                }
            }
            console.error(
                "MPGS Apple Pay completion failed:",
                error.code || "MPGS_APPLE_PAY_FAILED",
                mpgsGateway.mpgsErrorLogDetails(error)
            );
            const publicError = mpgsGateway.normalizeMpgsError(error);
            sendJSON(response, publicError.statusCode, { error: publicError.message });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/api/payments/card/session") {
        if (!await requireOperationalPayment("cardEnabled", response)) return;
        let body;
        try {
            body = await readBody(request, 16_384);
        } catch (error) {
            const publicError = mpgsGateway.normalizeMpgsError(error);
            sendJSON(response, publicError.statusCode === 413 ? 413 : 400, { error: publicError.message });
            return;
        }

        const authenticated = parseAuthenticatedCustomer(request, response);
        if (!authenticated) {
            return;
        }
        const customer = await resolveCustomerSession(authenticated, response);
        if (!customer) {
            return;
        }
        const localOrderID = normalizeCardPaymentIdentifier(body.orderID || body.orderId || body.localOrderId);
        if (!localOrderID) {
            sendJSON(response, 400, { error: "Provide a valid existing orderID." });
            return;
        }

        try {
            const result = await withCardPaymentLock(`${customer.email}:${localOrderID}`, async () => {
                const order = await findOrderByID(localOrderID);
                const existingPayment = await findPendingCardPayment(localOrderID, customer.email);
                if (existingPayment && existingPayment.paymentMethod !== "CARD") {
                    throw benefitPaymentError("MPGS_PAYMENT_METHOD_CONFLICT", 409, "Another payment method is already pending for this order.");
                }
                return mpgsGateway.initializeMpgsPayment({
                    configuration: mpgsConfiguration,
                    order,
                    customerEmail: customer.email,
                    existingPayment,
                    persistPayment: persistCardPayment
                });
            });
            console.info(
                `MPGS card session ${result.reused ? "reused" : "created"} for order ${localOrderID}: ${maskMpgsSessionID(result.payment.sessionID)}.`
            );
            sendJSON(response, 200, mpgsSessionResponse(result.payment));
        } catch (error) {
            console.error(`MPGS card session creation failed for order ${localOrderID}:`, error.code || "MPGS_SESSION_FAILED");
            const publicError = mpgsGateway.normalizeMpgsError(error);
            sendJSON(response, publicError.statusCode, { error: publicError.message });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/api/payments/card/session/retrieve") {
        let body;
        try {
            body = await readBody(request, 16_384);
        } catch (error) {
            const publicError = mpgsGateway.normalizeMpgsError(error);
            sendJSON(response, publicError.statusCode === 413 ? 413 : 400, { error: publicError.message });
            return;
        }
        const authenticated = parseAuthenticatedCustomer(request, response);
        if (!authenticated) {
            return;
        }
        const customer = await resolveCustomerSession(authenticated, response);
        if (!customer) {
            return;
        }
        const identifier = normalizeCardPaymentIdentifier(
            body.paymentSessionId || body.localOrderId || body.orderID || body.orderId
        );
        if (!identifier) {
            sendJSON(response, 400, { error: "Provide a valid orderID or paymentSessionId." });
            return;
        }

        try {
            const payment = await findCardPayment(identifier, customer.email);
            const order = payment ? await findOrderByID(payment.localOrderID) : null;
            mpgsGateway.verifyMpgsOrderPayment(payment, order, customer.email);
            const gatewaySession = await mpgsGateway.retrieveMpgsSession(mpgsConfiguration, payment.sessionID);
            mpgsGateway.verifyMpgsOrderPayment(payment, order, customer.email, gatewaySession);
            await updateCardPaymentSessionVersion(payment.paymentID, gatewaySession.session.version);
            console.info(`MPGS card session retrieved: ${maskMpgsSessionID(payment.sessionID)}.`);
            sendJSON(response, 200, sanitizedMpgsSessionStatus(payment, gatewaySession));
        } catch (error) {
            console.error("MPGS card session retrieval failed:", error.code || "MPGS_RETRIEVE_FAILED");
            const publicError = mpgsGateway.normalizeMpgsError(error);
            sendJSON(response, publicError.statusCode, { error: publicError.message });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/api/payments/card/authentication/initiate") {
        let body;
        try {
            body = await readBody(request, 16_384);
        } catch (error) {
            const publicError = mpgsGateway.normalizeMpgsError(error);
            sendJSON(response, publicError.statusCode === 413 ? 413 : 400, { error: publicError.message });
            return;
        }
        const authenticated = parseAuthenticatedCustomer(request, response);
        if (!authenticated) return;
        const customer = await resolveCustomerSession(authenticated, response);
        if (!customer) return;
        const localOrderID = normalizeCardPaymentIdentifier(body.localOrderId || body.orderID || body.orderId);
        const sessionID = normalizeCardPaymentIdentifier(body.sessionId, 100);
        if (!localOrderID || !sessionID) {
            sendJSON(response, 400, { error: "Provide a valid orderID and sessionId." });
            return;
        }
        try {
            const payment = await findCardPayment(localOrderID, customer.email);
            const order = payment ? await findOrderByID(payment.localOrderID) : null;
            mpgsGateway.verifyMpgsOrderPayment(payment, order, customer.email);
            if (payment.paymentMethod !== "CARD" || !timingSafeStringEqual(sessionID, payment.sessionID)) {
                throw benefitPaymentError("MPGS_SESSION_MISMATCH", 409, "Card payment session does not match.");
            }
            if (body.sdkManaged === true) {
                const requestedTransactionID = normalizeCardPaymentIdentifier(body.transactionId, 40);
                if (!requestedTransactionID) {
                    sendJSON(response, 400, { error: "Provide a valid SDK authentication transactionId." });
                    return;
                }
                const transactionID = payment.authenticationTransactionID || requestedTransactionID;
                if (payment.authenticationTransactionID
                    && !timingSafeStringEqual(payment.authenticationTransactionID, requestedTransactionID)) {
                    console.info(`MPGS SDK authentication reused for order ${localOrderID}.`);
                }
                await updateCardPaymentLifecycle(payment.paymentID, {
                    authenticationTransactionID: transactionID,
                    status: "Authenticating",
                    lastGatewayResponseAt: new Date().toISOString()
                });
                sendJSON(response, 200, {
                    authenticationTransactionId: transactionID,
                    sdkManaged: true
                });
                return;
            }
            const transactionID = payment.authenticationTransactionID || createMpgsTransactionID("AUTH");
            const gatewayResponse = await mpgsGateway.initiateMpgsAuthentication(mpgsConfiguration, {
                orderId: payment.mpgsOrderID,
                transactionId: transactionID,
                sessionId: payment.sessionID
            });
            await updateCardPaymentLifecycle(payment.paymentID, {
                authenticationTransactionID: transactionID,
                gatewayResult: String(gatewayResponse.result || "UNKNOWN"),
                status: "Authenticating",
                lastGatewayResponseAt: new Date().toISOString()
            });
            sendJSON(response, 200, {
                authenticationTransactionId: transactionID,
                recommendation: String(gatewayResponse.response?.gatewayRecommendation || "UNKNOWN"),
                gatewayResult: String(gatewayResponse.result || "UNKNOWN")
            });
        } catch (error) {
            console.error("MPGS authentication initiation failed:", error.code || "MPGS_AUTH_INIT_FAILED");
            const publicError = mpgsGateway.normalizeMpgsError(error);
            sendJSON(response, publicError.statusCode, { error: publicError.message });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/api/payments/card/authentication/complete") {
        let body;
        try {
            body = await readBody(request, 16_384);
        } catch (error) {
            const publicError = mpgsGateway.normalizeMpgsError(error);
            sendJSON(response, publicError.statusCode === 413 ? 413 : 400, { error: publicError.message });
            return;
        }
        const authenticated = parseAuthenticatedCustomer(request, response);
        if (!authenticated) return;
        const customer = await resolveCustomerSession(authenticated, response);
        if (!customer) return;
        const localOrderID = normalizeCardPaymentIdentifier(body.localOrderId || body.orderID || body.orderId);
        const sessionID = normalizeCardPaymentIdentifier(body.sessionId, 100);
        if (!localOrderID || !sessionID) {
            sendJSON(response, 400, { error: "Provide a valid orderID and sessionId." });
            return;
        }
        try {
            const payment = await findCardPayment(localOrderID, customer.email);
            const order = payment ? await findOrderByID(payment.localOrderID) : null;
            mpgsGateway.verifyMpgsOrderPayment(payment, order, customer.email);
            if (!payment.authenticationTransactionID || !timingSafeStringEqual(sessionID, payment.sessionID)) {
                throw benefitPaymentError("MPGS_AUTHENTICATION_REQUIRED", 409, "Payer authentication was not initiated.");
            }
            const gatewayResponse = await mpgsGateway.authenticateMpgsPayer(mpgsConfiguration, {
                orderId: payment.mpgsOrderID,
                transactionId: payment.authenticationTransactionID,
                sessionId: payment.sessionID,
                amount: payment.amount
            });
            const authenticationOutcome = mpgsGateway.normalizeMpgsAuthenticationOutcome(gatewayResponse);
            await updateCardPaymentLifecycle(payment.paymentID, {
                gatewayResult: authenticationOutcome.result,
                gatewayTransactionResult: authenticationOutcome.transactionStatus,
                status: authenticationOutcome.successful
                    ? "Authenticated"
                    : authenticationOutcome.challengeRequired
                        ? "AwaitingChallenge"
                        : authenticationOutcome.cancelled ? "Cancelled" : "AuthenticationFailed",
                lastGatewayResponseAt: new Date().toISOString()
            });
            sendJSON(response, authenticationOutcome.successful ? 200 : authenticationOutcome.challengeRequired ? 202 : 402, {
                authenticated: authenticationOutcome.successful,
                challengeRequired: authenticationOutcome.challengeRequired,
                cancelled: authenticationOutcome.cancelled,
                transactionStatus: authenticationOutcome.transactionStatus,
                recommendation: String(gatewayResponse.response?.gatewayRecommendation || "UNKNOWN"),
                ...(authenticationOutcome.challengeRequired ? { redirectHtml: authenticationOutcome.redirectHTML } : {})
            });
        } catch (error) {
            console.error("MPGS payer authentication failed:", error.code || "MPGS_AUTH_FAILED");
            const publicError = mpgsGateway.normalizeMpgsError(error);
            sendJSON(response, publicError.statusCode, { error: publicError.message });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/api/payments/card/order/retrieve") {
        let body;
        try {
            body = await readBody(request, 16_384);
        } catch (error) {
            const publicError = mpgsGateway.normalizeMpgsError(error);
            sendJSON(response, publicError.statusCode === 413 ? 413 : 400, { error: publicError.message });
            return;
        }
        const authenticated = parseAuthenticatedCustomer(request, response);
        if (!authenticated) return;
        const customer = await resolveCustomerSession(authenticated, response);
        if (!customer) return;
        const identifier = normalizeCardPaymentIdentifier(body.paymentSessionId || body.localOrderId || body.orderID || body.orderId);
        if (!identifier) {
            sendJSON(response, 400, { error: "Provide a valid orderID or paymentSessionId." });
            return;
        }
        try {
            const payment = await findCardPayment(identifier, customer.email);
            const order = payment ? await findOrderByID(payment.localOrderID) : null;
            mpgsGateway.verifyMpgsOrderPayment(payment, order, customer.email);
            const gatewayOrder = await mpgsGateway.retrieveMpgsOrder(mpgsConfiguration, payment.mpgsOrderID);
            let confirmed = false;
            try {
                verifyConfirmedMpgsOrder(payment, order, gatewayOrder);
                confirmed = true;
            } catch (error) {
                if (error.code !== "MPGS_PAYMENT_NOT_APPROVED") throw error;
            }
            sendJSON(response, 200, {
                paymentSessionId: payment.paymentID,
                orderId: payment.mpgsOrderID,
                status: confirmed ? "Captured" : payment.status,
                confirmed,
                amount: payment.amount,
                currency: "BHD"
            });
        } catch (error) {
            console.error("MPGS order retrieval failed:", error.code || "MPGS_ORDER_RETRIEVE_FAILED");
            const publicError = mpgsGateway.normalizeMpgsError(error);
            sendJSON(response, publicError.statusCode, { error: publicError.message });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/api/payments/card/complete") {
        let body;
        let paymentForFailure = null;
        try {
            body = await readBody(request, 16_384);
        } catch (error) {
            const publicError = mpgsGateway.normalizeMpgsError(error);
            sendJSON(response, publicError.statusCode === 413 ? 413 : 400, { error: publicError.message });
            return;
        }
        const authenticated = parseAuthenticatedCustomer(request, response);
        if (!authenticated) {
            return;
        }
        const customer = await resolveCustomerSession(authenticated, response);
        if (!customer) {
            return;
        }
        const localOrderID = normalizeCardPaymentIdentifier(body.localOrderId || body.orderID || body.orderId);
        const sessionID = normalizeCardPaymentIdentifier(body.sessionId, 100);
        if (!localOrderID || !sessionID) {
            sendJSON(response, 400, { error: "Provide a valid orderID and sessionId." });
            return;
        }

        try {
            const payment = await findCardPayment(localOrderID, customer.email);
            paymentForFailure = payment;
            const order = payment ? await findOrderByID(payment.localOrderID) : null;
            mpgsGateway.verifyMpgsOrderPayment(payment, order, customer.email);
            if (!timingSafeStringEqual(sessionID, payment.sessionID)) {
                sendJSON(response, 409, { error: "Card payment session does not match this order." });
                return;
            }
            const gatewaySession = await mpgsGateway.retrieveMpgsSession(mpgsConfiguration, payment.sessionID);
            mpgsGateway.verifyMpgsOrderPayment(payment, order, customer.email, gatewaySession);
            await updateCardPaymentSessionVersion(payment.paymentID, gatewaySession.session.version);
            const authenticationOrder = await mpgsGateway.retrieveMpgsOrder(mpgsConfiguration, payment.mpgsOrderID);
            verifyMpgsAuthenticationForPurchase(payment, authenticationOrder);
            if (payment.effectsAppliedAt) {
                sendJSON(response, 200, { status: "succeeded", orderId: payment.mpgsOrderID, duplicate: true });
                return;
            }
            const purchaseTransactionID = payment.purchaseTransactionID || createMpgsTransactionID("PAY");
            await updateCardPaymentLifecycle(payment.paymentID, {
                purchaseTransactionID,
                status: "Processing"
            });
            const purchaseResponse = await mpgsGateway.executeMpgsPurchase(mpgsConfiguration, {
                orderId: payment.mpgsOrderID,
                transactionId: purchaseTransactionID,
                authenticationTransactionId: payment.authenticationTransactionID,
                sessionId: payment.sessionID,
                amount: payment.amount
            });
            mpgsGateway.assertMpgsPaymentAccepted(purchaseResponse);
            const gatewayOrder = await mpgsGateway.retrieveMpgsOrder(mpgsConfiguration, payment.mpgsOrderID);
            const applied = await applyConfirmedMpgsPayment(payment.paymentID, gatewayOrder);
            console.info(`MPGS card payment confirmed for order ${localOrderID}: applied=${applied.applied}.`);
            sendJSON(response, 200, {
                status: "succeeded",
                orderId: payment.mpgsOrderID,
                duplicate: !applied.applied
            });
        } catch (error) {
            if (paymentForFailure && Number(error.statusCode) === 402) {
                try {
                    await updateCardPaymentLifecycle(paymentForFailure.paymentID, { status: "Declined" });
                } catch (storageError) {
                    console.error("MPGS card decline could not be recorded:", storageError.code || "MPGS_STORAGE_FAILED");
                }
            }
            console.error(
                "MPGS completion verification failed:",
                error.code || "MPGS_COMPLETE_FAILED",
                mpgsGateway.mpgsErrorLogDetails(error)
            );
            const publicError = mpgsGateway.normalizeMpgsError(error);
            sendJSON(response, publicError.statusCode, { error: publicError.message });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/api/payments/click-to-pay/create") {
        if (!await requireOperationalPayment("cardEnabled", response)) return;
        let body;
        try {
            body = await readBody(request, 16_384);
        } catch (error) {
            const publicError = mpgsGateway.normalizeMpgsError(error);
            sendJSON(response, publicError.statusCode === 413 ? 413 : 400, { error: publicError.message });
            return;
        }
        const authenticated = parseAuthenticatedCustomer(request, response);
        if (!authenticated) return;
        const customer = await resolveCustomerSession(authenticated, response);
        if (!customer) return;
        const localOrderID = normalizeCardPaymentIdentifier(body.orderID || body.orderId || body.localOrderId);
        if (!localOrderID) {
            sendJSON(response, 400, { error: "Provide a valid existing orderID." });
            return;
        }
        try {
            const result = await withCardPaymentLock(`${customer.email}:${localOrderID}`, async () => {
                const order = await findOrderByID(localOrderID);
                if (!order) throw benefitPaymentError("MPGS_ORDER_NOT_FOUND", 404, "Order not found.");
                if (!timingSafeStringEqual(normalizeEmail(order.email), normalizeEmail(customer.email))) {
                    throw benefitPaymentError("MPGS_ORDER_FORBIDDEN", 403, "This order does not belong to the authenticated customer.");
                }
                const existing = await findPendingCardPayment(localOrderID, customer.email);
                if (existing) {
                    throw benefitPaymentError("MPGS_PAYMENT_ALREADY_PENDING", 409, "A payment is already pending for this order.");
                }
                const amount = mpgsGateway.orderAmount(order);
                const identifiers = mpgsGateway.createMpgsIdentifiers();
                const resultToken = crypto.randomBytes(24).toString("base64url");
                const returnURL = publicPaymentURL("/api/payments/click-to-pay/return", resultToken);
                const cancelURL = publicPaymentURL("/api/payments/click-to-pay/return", resultToken, { cancelled: 1 });
                const gatewaySession = await mpgsGateway.initiateMpgsCheckout(mpgsConfiguration, {
                    orderId: identifiers.mpgsOrderID,
                    amount,
                    returnUrl: returnURL,
                    cancelUrl: cancelURL
                });
                const timestamp = new Date().toISOString();
                const payment = await persistCardPayment({
                    paymentID: identifiers.paymentID,
                    localOrderID,
                    mpgsOrderID: identifiers.mpgsOrderID,
                    sessionID: gatewaySession.session.id,
                    sessionVersion: String(gatewaySession.session.version),
                    amount,
                    currency: "BHD",
                    email: customer.email,
                    paymentMethod: "CLICK_TO_PAY",
                    resultTokenHash: sha256Hex(resultToken),
                    successIndicatorHash: sha256Hex(String(gatewaySession.successIndicator || "")),
                    gatewayResult: String(gatewaySession.result || "SUCCESS"),
                    status: "Pending",
                    createdAt: timestamp,
                    updatedAt: timestamp
                });
                return { payment, resultToken };
            });
            console.info(`MPGS Click to Pay session prepared: ${maskMpgsSessionID(result.payment.sessionID)}.`);
            sendJSON(response, 200, {
                paymentUrl: publicPaymentURL("/api/payments/click-to-pay/launch", result.resultToken),
                orderId: result.payment.mpgsOrderID,
                amount: result.payment.amount,
                currency: "BHD"
            });
        } catch (error) {
            console.error("MPGS Click to Pay creation failed:", error.code || "MPGS_CLICK_TO_PAY_FAILED");
            const publicError = mpgsGateway.normalizeMpgsError(error);
            sendJSON(response, publicError.statusCode, { error: publicError.message });
        }
        return;
    }

    if (request.method === "GET" && url.pathname === "/api/payments/click-to-pay/launch") {
        try {
            const resultToken = normalizeCardPaymentIdentifier(url.searchParams.get("payment"), 200);
            const payment = await findCardPaymentByResultToken(resultToken);
            if (!payment || payment.paymentMethod !== "CLICK_TO_PAY") {
                sendHTML(response, 404, renderMpgsResultPage("failure"), { "Cache-Control": "no-store" });
                return;
            }
            sendHTML(response, 200, renderClickToPayLaunch(payment, resultToken), {
                "Cache-Control": "no-store",
                "Referrer-Policy": "no-referrer",
                "X-Content-Type-Options": "nosniff"
            });
        } catch (error) {
            console.error("MPGS Click to Pay launch failed:", error.code || "MPGS_CLICK_LAUNCH_FAILED");
            sendHTML(response, 503, renderMpgsResultPage("failure"), { "Cache-Control": "no-store" });
        }
        return;
    }

    if (request.method === "GET" && url.pathname === "/api/payments/click-to-pay/return") {
        const resultToken = normalizeCardPaymentIdentifier(url.searchParams.get("payment"), 200);
        const cancelled = url.searchParams.get("cancelled") === "1";
        const errored = url.searchParams.get("error") === "1";
        const timedOut = url.searchParams.get("timeout") === "1";
        const resultIndicator = url.searchParams.get("resultIndicator")
            || url.searchParams.get("resultindicator");
        const returnedSessionVersion = String(url.searchParams.get("sessionVersion") || "").trim();
        let state = cancelled ? "cancelled" : errored ? "failure" : "pending";
        try {
            const payment = await findCardPaymentByResultToken(resultToken);
            if (!payment || payment.paymentMethod !== "CLICK_TO_PAY") {
                state = "failure";
            } else if (cancelled || errored || timedOut) {
                await updateCardPaymentLifecycle(payment.paymentID, {
                    status: cancelled ? "Cancelled" : errored ? "Failed" : "Pending",
                    lastGatewayResponseAt: new Date().toISOString(),
                    sessionVersion: returnedSessionVersion || null
                });
                state = cancelled ? "cancelled" : errored ? "failure" : "pending";
            } else if (!mpgsResultIndicatorMatches(payment, resultIndicator)) {
                console.warn("MPGS Click to Pay result indicator did not match.");
                state = "failure";
            } else {
                const order = await findOrderByID(payment.localOrderID);
                mpgsGateway.verifyMpgsOrderPayment(payment, order, payment.email);
                const gatewayOrder = await mpgsGateway.retrieveMpgsOrder(mpgsConfiguration, payment.mpgsOrderID);
                try {
                    const applied = await applyConfirmedMpgsPayment(payment.paymentID, gatewayOrder);
                    console.info(`MPGS Click to Pay confirmed: applied=${applied.applied}.`);
                    state = "success";
                } catch (error) {
                    if (error.code !== "MPGS_PAYMENT_NOT_APPROVED") throw error;
                    await updateCardPaymentLifecycle(payment.paymentID, {
                        status: cancelled ? "Cancelled" : errored ? "Failed" : "Pending",
                        gatewayResult: String(gatewayOrder.result || "UNKNOWN"),
                        lastGatewayResponseAt: new Date().toISOString()
                    });
                }
            }
        } catch (error) {
            console.error(
                "MPGS Click to Pay verification failed:",
                error.code || "MPGS_CLICK_VERIFY_FAILED",
                mpgsGateway.mpgsErrorLogDetails(error)
            );
            state = cancelled ? "cancelled" : errored ? "failure" : "pending";
        }
        sendHTML(response, 200, renderMpgsResultPage(state), {
            "Content-Security-Policy": "default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; form-action 'none'",
            "Cache-Control": "no-store",
            "Referrer-Policy": "no-referrer",
            "X-Content-Type-Options": "nosniff"
        });
        return;
    }

    if (request.method === "POST" && url.pathname === "/api/payments/benefitpay/session") {
        if (!await requireOperationalPayment("benefitPayEnabled", response)) return;
        let body;
        try {
            body = await readBody(request, 16_384);
        } catch (error) {
            sendJSON(response, error.code === "REQUEST_BODY_TOO_LARGE" ? 413 : 400, { error: "Invalid request." });
            return;
        }
        const authenticated = parseAuthenticatedCustomer(request, response);
        if (!authenticated) return;
        const customer = await resolveCustomerSession(authenticated, response);
        if (!customer) return;
        const orderID = normalizeBenefitIdentifier(body.orderID || body.orderId);
        if (!orderID) {
            sendJSON(response, 400, { error: "Provide a valid existing orderID." });
            return;
        }
        try {
            if (!benefitPayConfigured()) {
                throw benefitPaymentError("BENEFITPAY_NOT_CONFIGURED", 503, "BenefitPay is not configured.");
            }
            const order = await findOrderByID(orderID);
            if (!order) {
                throw benefitPaymentError("BENEFITPAY_ORDER_NOT_FOUND", 404, "Order not found.");
            }
            if (!timingSafeStringEqual(normalizeEmail(order.email), normalizeEmail(customer.email))) {
                throw benefitPaymentError("BENEFITPAY_ORDER_FORBIDDEN", 403, "This order does not belong to the authenticated customer.");
            }
            if (orderCurrency(order) !== "BHD") {
                throw benefitPaymentError("BENEFITPAY_CURRENCY_MISMATCH", 409, "The stored order currency is not BHD.");
            }
            const totalFils = bhdFils(numericOrderTotal(order));
            if (totalFils === null || totalFils <= 0) {
                throw benefitPaymentError("BENEFITPAY_AMOUNT_INVALID", 409, "The stored order does not have a valid payable total.");
            }
            const amount = (totalFils / 1000).toFixed(3);
            const referenceID = createBenefitPayReferenceID();
            const paymentToken = crypto.randomBytes(24).toString("base64url");
            await createBenefitPendingPayment({
                trackID: referenceID,
                orderID,
                email: customer.email,
                amount,
                currency: "BHD",
                resultTokenHash: sha256Hex(paymentToken),
                createdAt: new Date().toISOString()
            });
            console.info(`BenefitPay SDK session prepared for order ${orderID}.`);
            sendJSON(response, 200, {
                appId: benefitPayConfiguration.appID,
                merchantId: benefitPayConfiguration.merchantID,
                merchantName: normalizeBenefitPayMPQRText(benefitPayConfiguration.merchantName, 25),
                merchantCity: normalizeBenefitPayMPQRText(benefitPayConfiguration.merchantCity, 15),
                merchantCategoryCode: benefitPayConfiguration.merchantCategoryCode,
                countryCode: benefitPayConfiguration.countryCode,
                currencyCode: "048",
                amount,
                referenceId: referenceID,
                callbackTag: "tallabenefitpay",
                paymentToken,
                orderId: orderID
            });
        } catch (error) {
            console.error("BenefitPay SDK session creation failed:", error.code || "BENEFITPAY_SESSION_FAILED");
            const publicError = benefitPublicError(error);
            sendJSON(response, publicError.statusCode, { error: publicError.message });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/api/payments/benefitpay/confirm") {
        let body;
        try {
            body = await readBody(request, 16_384);
        } catch (error) {
            sendJSON(response, error.code === "REQUEST_BODY_TOO_LARGE" ? 413 : 400, { error: "Invalid request." });
            return;
        }
        const authenticated = parseAuthenticatedCustomer(request, response);
        if (!authenticated) return;
        const customer = await resolveCustomerSession(authenticated, response);
        if (!customer) return;
        const orderID = normalizeBenefitIdentifier(body.orderID || body.orderId);
        const referenceID = normalizeBenefitIdentifier(body.referenceID || body.referenceId);
        const paymentToken = normalizeBenefitIdentifier(body.paymentToken, 255);
        if (!orderID || !referenceID || !paymentToken) {
            sendJSON(response, 400, { error: "Provide a valid BenefitPay payment reference." });
            return;
        }
        try {
            if (!benefitPayConfigured()) {
                throw benefitPaymentError("BENEFITPAY_NOT_CONFIGURED", 503, "BenefitPay is not configured.");
            }
            const payment = await findBenefitPaymentByTrackID(referenceID);
            const order = payment ? await findOrderByID(payment.orderID) : null;
            if (!payment || !order || !timingSafeStringEqual(payment.orderID, orderID)) {
                throw benefitPaymentError("BENEFITPAY_PAYMENT_NOT_FOUND", 404, "BenefitPay payment was not found.");
            }
            if (!timingSafeStringEqual(normalizeEmail(payment.email), normalizeEmail(customer.email))) {
                throw benefitPaymentError("BENEFITPAY_ORDER_FORBIDDEN", 403, "This order does not belong to the authenticated customer.");
            }
            if (!timingSafeStringEqual(sha256Hex(paymentToken), payment.resultTokenHash)) {
                throw benefitPaymentError("BENEFITPAY_TOKEN_MISMATCH", 409, "BenefitPay payment reference does not match.");
            }
            const transaction = await queryBenefitPayTransaction(referenceID);
            const isPaid = String(transaction.status || "").toLowerCase() === "success";
            const notification = {
                trackID: referenceID,
                orderID,
                resultToken: paymentToken,
                amount: String(transaction.amount || ""),
                currency: String(transaction.currency || "").toUpperCase(),
                result: isPaid ? "CAPTURED" : "NOT CAPTURED",
                paymentID: String(transaction.transaction_receipt || transaction.reference_number || ""),
                transactionID: String(transaction.reference_number || transaction.transaction_receipt || ""),
                referenceID: String(transaction.reference_number || ""),
                authCode: String(transaction.authorization_code || ""),
                authResponseCode: isPaid ? "00" : "",
                errorCode: String(transaction.error_code || ""),
                errorText: String(transaction.error_description || "")
            };
            verifyBenefitNotification(payment, order, notification);
            await recordBenefitNotification(
                payment,
                notification,
                sha256Hex(JSON.stringify({ referenceID, status: notification.result }))
            );
            const result = await withBenefitPaymentLock(
                referenceID,
                () => applyBenefitNotification(referenceID, notification)
            );
            console.info(`BenefitPay transaction confirmed for order ${orderID}: applied=${result.applied}.`);
            sendJSON(response, 200, {
                status: isPaid ? "succeeded" : "failed",
                orderId: orderID,
                duplicate: isPaid && !result.applied
            });
        } catch (error) {
            const diagnostic = [
                `code=${error.code || "BENEFITPAY_CONFIRM_FAILED"}`,
                error.upstreamStatus ? `http=${error.upstreamStatus}` : "",
                error.providerStatus ? `providerStatus=${error.providerStatus}` : "",
                error.providerCode ? `providerCode=${error.providerCode}` : "",
                error.providerMessage ? `providerMessage=${error.providerMessage}` : ""
            ].filter(Boolean).join(" ");
            if (error.code === "BENEFITPAY_TRANSACTION_PENDING") {
                console.info(`BenefitPay transaction confirmation pending: ${diagnostic}`);
                sendJSON(response, 202, {
                    status: "pending",
                    orderId: orderID,
                    duplicate: false
                });
                return;
            }
            console.error(`BenefitPay transaction confirmation failed: ${diagnostic}`);
            const publicError = benefitPublicError(error);
            sendJSON(response, publicError.statusCode, { error: publicError.message });
        }
        return;
    }

    if (request.method === "POST" && benefitPathMatches(url.pathname, "/api/payments/benefit/create")) {
        if (!await requireOperationalPayment("benefitEnabled", response)) return;
        let body;
        let pendingTrackID = "";
        try {
            body = await readBody(request, 16_384);
        } catch (error) {
            const publicError = benefitPublicError(error);
            sendJSON(response, publicError.statusCode === 413 ? 413 : 400, { error: publicError.message });
            return;
        }

        try {
            const authenticated = parseAuthenticatedCustomer(request, response);
            if (!authenticated) {
                return;
            }
            const customer = await resolveCustomerSession(authenticated, response);
            if (!customer) {
                return;
            }

            const orderID = normalizeBenefitIdentifier(body.orderID || body.orderId || body.invoiceId);
            if (!orderID) {
                sendJSON(response, 400, { error: "Provide a valid existing orderID." });
                return;
            }
            if (!benefitConfigured()) {
                console.error("BENEFIT payment creation is unavailable because required configuration is missing.");
                sendJSON(response, 503, { error: "BENEFIT checkout is not configured." });
                return;
            }

            const order = await findOrderByID(orderID);
            if (!order) {
                throw benefitPaymentError("BENEFIT_ORDER_NOT_FOUND", 404, "Order not found.");
            }
            if (!timingSafeStringEqual(normalizeEmail(order.email), normalizeEmail(customer.email))) {
                throw benefitPaymentError("BENEFIT_ORDER_FORBIDDEN", 403, "This order does not belong to the authenticated customer.");
            }
            if (orderCurrency(order) !== "BHD") {
                throw benefitPaymentError("BENEFIT_CURRENCY_MISMATCH", 409, "The stored order currency is not BHD.");
            }
            const total = numericOrderTotal(order);
            const totalFils = bhdFils(total);
            if (totalFils === null || totalFils <= 0) {
                throw benefitPaymentError("BENEFIT_AMOUNT_INVALID", 409, "The stored order does not have a valid payable total.");
            }

            const endpointURL = safeConfiguredBenefitURL(
                benefitAPIEndpoint,
                "BENEFIT API endpoint",
                "/payment/API/hosted.htm"
            );
            const notificationURL = safeConfiguredBenefitURL(
                benefitNotificationURL,
                "BENEFIT notification URL",
                "/api/payments/benefit/response"
            ).toString();
            const amount = (totalFils / 1000).toFixed(3);
            const trackID = `T${Date.now()}${crypto.randomBytes(10).toString("hex")}`;
            pendingTrackID = trackID;
            const resultToken = crypto.randomBytes(24).toString("base64url");
            const createdAt = new Date().toISOString();
            await createBenefitPendingPayment({
                trackID,
                orderID,
                email: customer.email,
                amount,
                currency: "BHD",
                resultTokenHash: sha256Hex(resultToken),
                createdAt
            });

            const requestPlaintext = benefitGateway.buildBenefitRequestPlaintext({
                amount,
                tranportalID: benefitTranportalID,
                tranportalPassword: benefitTranportalPassword,
                resourceKey: benefitResourceKey,
                trackID,
                responseURL: notificationURL,
                errorURL: notificationURL,
                orderID,
                resultToken
            });
            const encryptedTransactionData = benefitGateway.encryptBenefitPayload(
                requestPlaintext,
                benefitResourceKey
            );
            const upstreamResponse = await fetch(endpointURL, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    Accept: "application/json",
                    charset: "utf8"
                },
                body: benefitGateway.buildBenefitAPIRequestBody(
                    benefitTranportalID,
                    encryptedTransactionData
                ),
                signal: AbortSignal.timeout(15_000)
            });
            const responseText = await upstreamResponse.text();
            if (responseText.length > 131_072) {
                throw benefitPaymentError("BENEFIT_INVALID_RESPONSE", 502, "BENEFIT returned an invalid response.");
            }
            let upstreamPayload;
            try {
                upstreamPayload = JSON.parse(responseText);
            } catch (error) {
                throw benefitPaymentError("BENEFIT_INVALID_RESPONSE", 502, "BENEFIT returned an invalid response.");
            }
            const result = Array.isArray(upstreamPayload) ? upstreamPayload[0] : upstreamPayload;
            if (!upstreamResponse.ok || String(result?.status || "") !== "1" || !result?.result) {
                throw benefitPaymentError("BENEFIT_INITIATION_FAILED", 502, "BENEFIT could not create the hosted payment.");
            }
            const paymentURL = validateBenefitHostedPaymentURL(result.result);
            await updateBenefitPaymentInitiation(trackID, paymentURL, "Initiated");
            console.info(`BENEFIT payment initiated for order ${orderID} with track ${trackID}.`);
            sendJSON(response, 200, {
                paymentUrl: paymentURL,
                trackId: trackID
            });
        } catch (error) {
            if (pendingTrackID) {
                try {
                    await updateBenefitPaymentInitiation(pendingTrackID, null, "InitiationFailed");
                } catch (storageError) {
                    console.error(
                        `BENEFIT initiation failure could not be recorded for track ${pendingTrackID}:`,
                        storageError.code || "BENEFIT_STORAGE_FAILED"
                    );
                }
            }
            console.error("BENEFIT payment initiation failed:", error.code || "BENEFIT_INITIATION_FAILED");
            const publicError = benefitPublicError(error);
            sendJSON(response, publicError.statusCode, { error: publicError.message });
        }
        return;
    }

    if (request.method === "POST" && benefitPathMatches(url.pathname, "/api/payments/benefit/status")) {
        let body;
        try {
            body = await readBody(request, 4_096);
        } catch (error) {
            const publicError = benefitPublicError(error);
            sendJSON(response, publicError.statusCode === 413 ? 413 : 400, { error: publicError.message });
            return;
        }

        try {
            const authenticated = parseAuthenticatedCustomer(request, response);
            if (!authenticated) {
                return;
            }
            const customer = await resolveCustomerSession(authenticated, response);
            if (!customer) {
                return;
            }
            const orderID = normalizeBenefitIdentifier(body.orderID || body.orderId);
            if (!orderID) {
                sendJSON(response, 400, { error: "Provide a valid existing orderID." });
                return;
            }
            const order = await findOrderByID(orderID);
            if (!order) {
                throw benefitPaymentError("BENEFIT_ORDER_NOT_FOUND", 404, "Order not found.");
            }
            if (!timingSafeStringEqual(normalizeEmail(order.email), normalizeEmail(customer.email))) {
                throw benefitPaymentError("BENEFIT_ORDER_FORBIDDEN", 403, "This order does not belong to the authenticated customer.");
            }
            const payment = await findBenefitPaymentByOrderID(orderID);
            if (!payment || !timingSafeStringEqual(normalizeEmail(payment.email), normalizeEmail(customer.email))) {
                throw benefitPaymentError("BENEFIT_PAYMENT_NOT_FOUND", 404, "BENEFIT payment was not found.");
            }
            sendJSON(response, 200, {
                orderId: orderID,
                ...benefitClientPaymentStatus(payment)
            });
        } catch (error) {
            const publicError = benefitPublicError(error);
            sendJSON(response, publicError.statusCode, { error: publicError.message });
        }
        return;
    }

    if (request.method === "POST" && benefitPathMatches(url.pathname, "/api/payments/benefit/response")) {
        let fallbackErrorURL;
        try {
            fallbackErrorURL = benefitResultURL(benefitErrorURL);
        } catch (error) {
            sendJSON(response, 503, { error: "BENEFIT callback is not configured." });
            return;
        }

        let notification;
        let payment;
        try {
            const rawBody = await readRawBody(request, 65_536);
            const callback = parseBenefitCallbackRequest(rawBody, request.headers["content-type"]);
            if (callback.trandata) {
                const decrypted = benefitGateway.decryptBenefitPayload(callback.trandata, benefitResourceKey);
                const record = benefitGateway.parseBenefitNotificationPlaintext(decrypted);
                notification = benefitGateway.normalizeBenefitNotification(record);
            } else {
                notification = benefitGateway.normalizeBenefitNotification(callback);
            }

            notification.trackID = normalizeBenefitIdentifier(notification.trackID);
            notification.resultToken = normalizeBenefitIdentifier(notification.resultToken, 200);
            if (!notification.trackID) {
                throw benefitPaymentError("BENEFIT_TRACK_MISSING", 400, "BENEFIT callback is missing a track ID.");
            }
            payment = await findBenefitPaymentByTrackID(notification.trackID);
            const order = payment ? await findOrderByID(payment.orderID) : null;
            verifyBenefitNotification(payment, order, notification);
            const notificationHash = crypto.createHash("sha256").update(rawBody).digest("hex");
            await recordBenefitNotification(payment, notification, notificationHash);

            const isCaptured = notification.result === "CAPTURED"
                && notification.authResponseCode === "00"
                && !notification.errorCode;
            const redirectURL = benefitResultURL(
                isCaptured ? benefitSuccessURL : benefitErrorURL,
                notification.resultToken
            );
            sendBenefitRedirectAcknowledgement(response, redirectURL);
            console.info(
                `BENEFIT notification recorded for track ${notification.trackID}: result=${notification.result || "ERROR"}.`
            );
            setImmediate(() => {
                void withBenefitPaymentLock(
                    notification.trackID,
                    () => applyBenefitNotification(notification.trackID, notification)
                ).then((result) => {
                    console.info(
                        `BENEFIT notification processed for track ${notification.trackID}: applied=${result.applied}.`
                    );
                }).catch((error) => {
                    console.error(
                        `BENEFIT notification processing failed for track ${notification.trackID}:`,
                        error.code || "BENEFIT_PROCESSING_FAILED"
                    );
                });
            });
        } catch (error) {
            const validationDetails = Array.isArray(error.validationIssues) && error.validationIssues.length > 0
                ? ` missing=${error.validationIssues.join(",")}`
                : "";
            console.error(
                `BENEFIT notification rejected${notification?.trackID ? ` for track ${notification.trackID}` : ""}:`,
                `${error.code || "BENEFIT_CALLBACK_INVALID"}${validationDetails}`
            );
            sendBenefitRedirectAcknowledgement(response, fallbackErrorURL);
        }
        return;
    }

    const isBenefitBrowserResultRequest = request.method === "GET"
        ? isBenefitBrowserReturnPath(url.pathname)
        : request.method === "POST"
            && isBenefitBrowserReturnPath(url.pathname)
            && !benefitPathMatches(url.pathname, "/api/payments/benefit/response");
    if (isBenefitBrowserResultRequest) {
        const htmlHeaders = benefitResultPageHeaders();
        try {
            let returnURL = url;
            if (request.method === "POST") {
                const rawBody = await readRawBody(request, 16_384);
                const formParameters = new URLSearchParams(rawBody.toString("utf8"));
                returnURL = new URL(url);
                for (const [key, value] of formParameters) {
                    if (!returnURL.searchParams.has(key)) {
                        returnURL.searchParams.set(key, value);
                    }
                }
            }
            const payment = await findBenefitPaymentForBrowserReturn(returnURL);
            sendHTML(response, 200, renderBenefitResultPage(payment), htmlHeaders);
        } catch (error) {
            console.error("BENEFIT browser return failed:", error.code || error.message || "BENEFIT_BROWSER_RETURN_FAILED");
            sendHTML(response, 200, renderBenefitResultPage(null), htmlHeaders);
        }
        return;
    }

    if (request.method === "GET" && url.pathname === "/") {
        const htmlHeaders = benefitResultPageHeaders();
        try {
            const payment = await findBenefitPaymentForBrowserReturn(url);
            sendHTML(response, 200, renderBenefitResultPage(payment), htmlHeaders);
        } catch (error) {
            console.error("BENEFIT root return page failed:", error.code || error.message || "BENEFIT_ROOT_RETURN_FAILED");
            sendHTML(response, 200, renderBenefitResultPage(null), htmlHeaders);
        }
        return;
    }

    if (request.method === "GET" && url.pathname === "/orders") {
        const requestedEmail = normalizeEmail(url.searchParams.get("email"));
        const authenticated = parseAuthenticatedCustomer(request, response, requestedEmail || null);
        if (!authenticated) {
            return;
        }

        const customer = await resolveCustomerSession(authenticated, response);
        if (!customer) {
            return;
        }

        const customerAccount = await getAccountByEmail(customer.email);
        if (!customerAccount) {
            sendJSON(response, 404, { error: "Account not found" });
            return;
        }

        try {
            await syncRecentShopifyOrdersForEmail(customer.email);
        } catch (error) {
            console.warn(`Shopify order sync skipped for ${customer.email}:`, error.message);
        }

        const customerOrders = await ordersPayload(customer.email);
        customerOrders
            .filter((order) => completedOrderStatuses().has(order.status))
            .forEach((order) => queueShopifyOrderExport(order.id));
        sendJSON(response, 200, customerOrders);
        return;
    }

    if (request.method === "GET" && url.pathname === "/taste-memory") {
        const requestedEmail = normalizeEmail(url.searchParams.get("email"));
        const authenticated = parseAuthenticatedCustomer(request, response, requestedEmail || null);
        if (!authenticated) {
            return;
        }

        const customer = await resolveCustomerSession(authenticated, response);
        if (!customer) {
            return;
        }

        sendJSON(response, 200, await tasteMemoryPayload(customer.email));
        return;
    }

    if (request.method === "POST" && url.pathname === "/taste-memory/save") {
        try {
            const body = await readBody(request);
            const requestedEmail = normalizeEmail(body.email);
            const authenticated = parseAuthenticatedCustomer(request, response, requestedEmail || null);
            if (!authenticated) {
                return;
            }

            const customer = await resolveCustomerSession(authenticated, response);
            if (!customer) {
                return;
            }

            const record = await saveTasteMemoryRecord(customer.email, body);
            if (!record) {
                sendJSON(response, 400, { error: "Invalid taste memory payload." });
                return;
            }

            sendJSON(response, 200, {
                record,
                tasteMemory: await tasteMemoryPayload(customer.email)
            });
        } catch (error) {
            sendJSON(response, 400, { error: "Invalid taste memory payload." });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/coffee-data/sync") {
        try {
            const body = await readBody(request);
            const authenticated = parseAuthenticatedCustomer(request, response);
            if (!authenticated) return;
            const customer = await resolveCustomerSession(authenticated, response);
            if (!customer) return;
            const deviceID = trimText(body.deviceID, 100);
            if (!deviceID) { sendJSON(response, 400, { error: "deviceID is required." }); return; }
            const result = await synchronizeCoffeeRecords(customer.email, deviceID, body.cursor, body.changes);
            sendJSON(response, 200, result);
        } catch (error) {
            console.error("Coffee data sync failed:", error);
            sendJSON(response, error.statusCode || 500, { error: error.statusCode ? "Invalid coffee sync payload." : "Coffee sync unavailable." });
        }
        return;
    }

    if (request.method === "GET" && url.pathname === "/customer-library") {
        const authenticated = parseAuthenticatedCustomer(request, response);
        if (!authenticated) return;

        const customer = await resolveCustomerSession(authenticated, response);
        if (!customer) return;

        sendJSON(response, 200, await customerLibraryPayload(customer.email));
        return;
    }

    if (request.method === "POST" && url.pathname === "/customer-library") {
        try {
            const body = await readBody(request);
            const authenticated = parseAuthenticatedCustomer(request, response);
            if (!authenticated) return;

            const customer = await resolveCustomerSession(authenticated, response);
            if (!customer) return;

            const library = await mutateCustomerLibrary(customer.email, body);
            if (!library) {
                sendJSON(response, 400, { error: "Invalid customer library payload." });
                return;
            }
            sendJSON(response, 200, library);
        } catch (error) {
            sendJSON(response, 400, { error: "Invalid customer library payload." });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/orders/checkout-started") {
        try {
            const body = await readBody(request);
            const requestedEmail = normalizeEmail(body.email);
            const authenticated = parseAuthenticatedCustomer(request, response, requestedEmail || null);
            if (!authenticated) {
                return;
            }

            const customer = await resolveCustomerSession(authenticated, response);
            if (!customer) {
                return;
            }

            const customerAccount = await getAccountByEmail(customer.email);
            if (!customerAccount) {
                sendJSON(response, 404, { error: "Account not found" });
                return;
            }

            const submittedItems = Array.isArray(body.items) ? body.items : [];
            const items = submittedItems
                .map((item) => {
                    const variantID = String(item.variantId || item.variantID || "").trim();
                    return {
                        name: String(item.name || "Item").trim() || "Item",
                        quantity: Math.max(1, Math.round(Number(item.quantity || 1))),
                        ...(variantID.startsWith("gid://shopify/ProductVariant/") ? { variantId: variantID } : {})
                    };
                })
                .slice(0, 30);

            if (items.length === 0) {
                sendJSON(response, 400, { error: "Order items are required." });
                return;
            }

            const totalNumber = Number(body.total);
            const safeTotal = Number.isFinite(totalNumber) && totalNumber >= 0 ? totalNumber : 0;
            const pendingOrder = {
                id: `checkout_${Date.now()}`,
                email: customer.email,
                title: String(body.title || "Checkout started").trim() || "Checkout started",
                total: `BHD ${safeTotal.toFixed(3)}`,
                totalNumber: safeTotal,
                status: "Pending",
                items,
                createdAt: new Date().toISOString()
            };

            await upsertOrderRecord(pendingOrder);
            void recordTelemetry({
                id: `checkout_${pendingOrder.id}`,
                eventName: "checkout_started",
                category: "analytics",
                platform: "backend",
                anonymousId: `account:${crypto.createHash("sha256").update(customer.email).digest("hex").slice(0, 24)}`,
                sessionId: pendingOrder.id,
                appVersion: "server",
                occurredAt: pendingOrder.createdAt,
                properties: { itemCount: items.reduce((sum, item) => sum + item.quantity, 0), total: safeTotal }
            }, customer.email).catch((error) => {
                console.error("Checkout telemetry failed:", error.code || error.message || "TELEMETRY_FAILED");
            });
            sendJSON(response, 200, {
                orderID: pendingOrder.id,
                orders: await ordersPayload(customer.email)
            });
        } catch (error) {
            sendJSON(response, 400, { error: "Invalid checkout order." });
        }
        return;
    }

    if (request.method === "GET" && url.pathname === "/alerts") {
        const requestedEmail = normalizeEmail(url.searchParams.get("email"));
        const authenticated = parseAuthenticatedCustomer(request, response, requestedEmail || null);
        if (!authenticated) {
            return;
        }

        const customer = await resolveCustomerSession(authenticated, response);
        if (!customer) {
            return;
        }

        const customerAccount = await getAccountByEmail(customer.email);
        if (!customerAccount) {
            sendJSON(response, 404, { error: "Account not found" });
            return;
        }

        sendJSON(response, 200, await stockAlertsFor(customer.email));
        return;
    }

    if (request.method === "GET" && url.pathname === "/alerts/inbox") {
        const requestedEmail = normalizeEmail(url.searchParams.get("email"));
        const authenticated = parseAuthenticatedCustomer(request, response, requestedEmail || null);
        if (!authenticated) {
            return;
        }

        const customer = await resolveCustomerSession(authenticated, response);
        if (!customer) {
            return;
        }

        const customerAccount = await getAccountByEmail(customer.email);
        if (!customerAccount) {
            sendJSON(response, 404, { error: "Account not found" });
            return;
        }

        sendJSON(response, 200, await alertInboxFor(customer.email));
        return;
    }

    if (request.method === "POST" && url.pathname === "/notifications/push/register") {
        try {
            const body = await readBody(request);
            const requestedEmail = normalizeEmail(body.email);
            const authenticated = parseAuthenticatedCustomer(request, response, requestedEmail || null);
            if (!authenticated) {
                return;
            }

            const customer = await resolveCustomerSession(authenticated, response);
            if (!customer) {
                return;
            }

            const customerAccount = await getAccountByEmail(customer.email);
            if (!customerAccount) {
                sendJSON(response, 404, { error: "Account not found" });
                return;
            }

            const deviceToken = normalizeDeviceToken(body.deviceToken);
            const platform = String(body.platform || "ios").trim().toLowerCase() || "ios";
            if (!deviceToken) {
                sendJSON(response, 400, { error: "Invalid push device token" });
                return;
            }
            if (!["ios", "android"].includes(platform)) {
                sendJSON(response, 400, { error: "Invalid push platform" });
                return;
            }

            const device = await registerPushDevice(customer.email, deviceToken, platform);
            sendJSON(response, 200, { status: "ok", device });
        } catch (error) {
            sendJSON(response, 400, { error: "Invalid JSON body" });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/notifications/push/unregister") {
        try {
            const body = await readBody(request);
            const requestedEmail = normalizeEmail(body.email);
            const authenticated = parseAuthenticatedCustomer(request, response, requestedEmail || null);
            if (!authenticated) {
                return;
            }

            const customer = await resolveCustomerSession(authenticated, response);
            if (!customer) {
                return;
            }

            const customerAccount = await getAccountByEmail(customer.email);
            if (!customerAccount) {
                sendJSON(response, 404, { error: "Account not found" });
                return;
            }

            const deviceToken = normalizeDeviceToken(body.deviceToken);
            if (!deviceToken) {
                sendJSON(response, 400, { error: "Invalid push device token" });
                return;
            }

            await unregisterPushDevice(customer.email, deviceToken);
            sendJSON(response, 200, { status: "ok" });
        } catch (error) {
            sendJSON(response, 400, { error: "Invalid JSON body" });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/alerts/watch") {
        try {
            const body = await readBody(request);
            const productID = String(body.productID || "").trim();
            const productName = String(body.productName || "").trim();
            const requestedEmail = normalizeEmail(body.email);
            const authenticated = parseAuthenticatedCustomer(request, response, requestedEmail || null);
            if (!authenticated) {
                return;
            }

            const customer = await resolveCustomerSession(authenticated, response);
            if (!customer) {
                return;
            }

            if (!productID || !productName) {
                sendJSON(response, 400, { error: "Invalid alert payload" });
                return;
            }

            const customerAccount = await getAccountByEmail(customer.email);
            if (!customerAccount) {
                sendJSON(response, 404, { error: "Account not found" });
                return;
            }

            const record = await upsertStockAlert(customer.email, {
                productID,
                productName,
                tag: body.tag ? String(body.tag).trim() : null,
                isAvailableForSale: Boolean(body.isAvailableForSale)
            });

            sendJSON(response, 200, record);
        } catch (error) {
            sendJSON(response, 400, { error: "Invalid JSON body" });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/alerts/unwatch") {
        try {
            const body = await readBody(request);
            const productID = String(body.productID || "").trim();
            const requestedEmail = normalizeEmail(body.email);
            const authenticated = parseAuthenticatedCustomer(request, response, requestedEmail || null);
            if (!authenticated) {
                return;
            }

            const customer = await resolveCustomerSession(authenticated, response);
            if (!customer) {
                return;
            }

            if (!productID) {
                sendJSON(response, 400, { error: "Invalid alert payload" });
                return;
            }

            const customerAccount = await getAccountByEmail(customer.email);
            if (!customerAccount) {
                sendJSON(response, 404, { error: "Account not found" });
                return;
            }

            await removeStockAlert(customer.email, productID);
            sendJSON(response, 200, { status: "ok" });
        } catch (error) {
            sendJSON(response, 400, { error: "Invalid JSON body" });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/alerts/sync") {
        try {
            const body = await readBody(request);
            const alerts = Array.isArray(body.alerts) ? body.alerts : [];
            const requestedEmail = normalizeEmail(body.email);
            const authenticated = parseAuthenticatedCustomer(request, response, requestedEmail || null);
            if (!authenticated) {
                return;
            }

            const customer = await resolveCustomerSession(authenticated, response);
            if (!customer) {
                return;
            }

            const customerAccount = await getAccountByEmail(customer.email);
            if (!customerAccount) {
                sendJSON(response, 404, { error: "Account not found" });
                return;
            }

            const synced = await syncStockAlerts(
                customer.email,
                alerts
                    .map((alert) => ({
                        productID: String(alert.productID || "").trim(),
                        productName: String(alert.productName || "").trim(),
                        tag: alert.tag ? String(alert.tag).trim() : null,
                        isAvailableForSale: Boolean(alert.isAvailableForSale)
                    }))
                    .filter((alert) => alert.productID && alert.productName)
            );

            sendJSON(response, 200, synced);
        } catch (error) {
            sendJSON(response, 400, { error: "Invalid JSON body" });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/orders/sample") {
        try {
            const body = await readBody(request);
            const requestedEmail = normalizeEmail(body.email);
            const authenticated = parseAuthenticatedCustomer(request, response, requestedEmail || null);
            if (!authenticated) {
                return;
            }

            const customer = await resolveCustomerSession(authenticated, response);
            if (!customer) {
                return;
            }

            const customerAccount = await getAccountByEmail(customer.email);
            if (!customerAccount) {
                sendJSON(response, 404, { error: "Account not found" });
                return;
            }

            const newOrder = {
                id: `ord_${Date.now()}`,
                title: "Roastery Order",
                total: `BHD ${sampleOrderTotal.toFixed(3)}`,
                status: "Completed",
                items: sampleOrderItems,
                createdAt: new Date().toISOString()
            };

            let orders;
            if (database.isEnabled()) {
                await database.query(
                    `INSERT INTO orders
                     (id, email, title, total, status, items, created_at)
                     VALUES ($1, $2, $3, $4, $5, $6::jsonb, $7)`,
                    [newOrder.id, customer.email, newOrder.title, newOrder.total, newOrder.status, JSON.stringify(newOrder.items), newOrder.createdAt]
                );
                orders = await ordersPayload(customer.email);
            } else {
                const store = readJSON(ordersStorePath);
                orders = store.orders[customer.email] || [];
                orders.unshift(newOrder);
                store.orders[customer.email] = orders;
                writeJSON(ordersStorePath, store);
            }

            const awardedPoints = Math.round(sampleOrderTotal * runtimeAppSettings.value.loyalty.pointsPerBHD);
            await updateLoyaltyAccount(customer.email, (account) => {
                account.pointsBalance += awardedPoints;
                account.transactions = account.transactions || [];
                account.transactions.unshift({
                    id: `txn_${Date.now()}`,
                    type: "earn",
                    points: awardedPoints,
                    note: `Completed order • ${awardedPoints} Beans • BHD ${sampleOrderTotal.toFixed(3)}`,
                    createdAt: new Date().toISOString()
                });
            });

            sendJSON(response, 200, orders);
        } catch (error) {
            sendJSON(response, 400, { error: "Invalid JSON body" });
        }
        return;
    }

    if (request.method === "GET" && url.pathname === "/addresses") {
        const requestedEmail = normalizeEmail(url.searchParams.get("email"));
        const authenticated = parseAuthenticatedCustomer(request, response, requestedEmail || null);
        if (!authenticated) {
            return;
        }

        const customer = await resolveCustomerSession(authenticated, response);
        if (!customer) {
            return;
        }

        const customerAccount = await getAccountByEmail(customer.email);
        if (!customerAccount) {
            sendJSON(response, 404, { error: "Account not found" });
            return;
        }

        sendJSON(response, 200, await addressesFor(customer.email));
        return;
    }

    if (request.method === "POST" && url.pathname === "/addresses/save") {
        try {
            const body = await readBody(request);
            const label = String(body.label || "").trim();
            const fullName = String(body.fullName || "").trim();
            const phone = String(body.phone || "").trim();
            const line1 = String(body.line1 || "").trim();
            const city = String(body.city || "").trim();
            const countryCode = normalizeCountryCode(body.countryCode);
            const requestedEmail = normalizeEmail(body.email);
            const authenticated = parseAuthenticatedCustomer(request, response, requestedEmail || null);
            if (!authenticated) {
                return;
            }

            const customer = await resolveCustomerSession(authenticated, response);
            if (!customer) {
                return;
            }

            if (!label || !fullName || !phone || !line1 || !city || !countryCode) {
                sendJSON(response, 400, { error: "Invalid address payload" });
                return;
            }

            const customerAccount = await getAccountByEmail(customer.email);
            if (!customerAccount) {
                sendJSON(response, 404, { error: "Account not found" });
                return;
            }

            sendJSON(response, 200, await saveAddress(customer.email, {
                label,
                fullName,
                phone,
                line1,
                city,
                countryCode,
                isPreferred: body.isPreferred !== false,
                notes: body.notes ? String(body.notes).trim() : null
            }));
        } catch (error) {
            sendJSON(response, 400, { error: "Invalid JSON body" });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/addresses/delete") {
        try {
            const body = await readBody(request);
            const addressID = String(body.addressID || "").trim();
            const requestedEmail = normalizeEmail(body.email);
            const authenticated = parseAuthenticatedCustomer(request, response, requestedEmail || null);
            if (!authenticated) {
                return;
            }

            const customer = await resolveCustomerSession(authenticated, response);
            if (!customer) {
                return;
            }

            if (!addressID) {
                sendJSON(response, 400, { error: "Invalid address payload" });
                return;
            }

            const customerAccount = await getAccountByEmail(customer.email);
            if (!customerAccount) {
                sendJSON(response, 404, { error: "Account not found" });
                return;
            }

            sendJSON(response, 200, await deleteAddress(customer.email, addressID));
        } catch (error) {
            sendJSON(response, 400, { error: "Invalid JSON body" });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/addresses/preferred") {
        try {
            const body = await readBody(request);
            const addressID = String(body.addressID || "").trim();
            const requestedEmail = normalizeEmail(body.email);
            const authenticated = parseAuthenticatedCustomer(request, response, requestedEmail || null);
            if (!authenticated) return;

            const customer = await resolveCustomerSession(authenticated, response);
            if (!customer) return;

            if (!addressID) {
                sendJSON(response, 400, { error: "Invalid address payload" });
                return;
            }

            const addresses = await setPreferredAddress(customer.email, addressID);
            if (!addresses) {
                sendJSON(response, 404, { error: "Address not found" });
                return;
            }
            sendJSON(response, 200, addresses);
        } catch (error) {
            sendJSON(response, 400, { error: "Invalid JSON body" });
        }
        return;
    }

    if (request.method === "GET" && url.pathname === "/wallet/pass") {
        const requestedEmail = normalizeEmail(url.searchParams.get("email"));
        const authenticated = parseAuthenticatedCustomer(request, response, requestedEmail || null);
        if (!authenticated) {
            return;
        }

        const customer = await resolveCustomerSession(authenticated, response);
        if (!customer) {
            return;
        }

        const customerAccount = await getAccountByEmail(customer.email);
        if (!customerAccount) {
            sendJSON(response, 404, { error: "Account not found" });
            return;
        }

        try {
            const generatedPass = await generateWalletPass(customer.email);

            response.writeHead(200, {
                "Content-Type": "application/vnd.apple.pkpass",
                "Content-Length": fs.statSync(generatedPass.path).size,
                "Access-Control-Allow-Origin": "*"
            });

            const stream = fs.createReadStream(generatedPass.path);
            stream.on("close", () => generatedPass.cleanup());
            stream.on("error", () => generatedPass.cleanup());
            stream.pipe(response);
        } catch (error) {
            sendJSON(response, 500, { error: error.message || "Could not generate Wallet pass" });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/loyalty/transactions/earn") {
        try {
            const body = await readBody(request);
            const points = Number(body.points);
            const note = String(body.note || "Beans adjustment");
            const requestedEmail = normalizeEmail(body.email);
            const authenticated = parseAuthenticatedCustomer(request, response, requestedEmail || null);
            if (!authenticated) {
                return;
            }

            const customer = await resolveCustomerSession(authenticated, response);
            if (!customer) {
                return;
            }

            if (!Number.isFinite(points) || points <= 0) {
                sendJSON(response, 400, { error: "Invalid earn payload" });
                return;
            }

            const updated = await updateLoyaltyAccount(customer.email, (account) => {
                account.pointsBalance += points;
                account.transactions = account.transactions || [];
                account.transactions.unshift({
                    id: `txn_${Date.now()}`,
                    type: "earn",
                    points,
                    note,
                    createdAt: new Date().toISOString()
                });
            });

            if (!updated) {
                sendJSON(response, 404, { error: "Account not found" });
                return;
            }

            sendJSON(response, 200, loyaltyPayload(updated));
        } catch (error) {
            sendJSON(response, 400, { error: "Invalid JSON body" });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/loyalty/transactions/redeem") {
        try {
            const body = await readBody(request);
            const requestedReward = String(body.reward || "").trim();
            const loyaltySettings = (await getAppSettings()).loyalty;
            const catalogReward = loyaltySettings.rewards.find((entry) => entry.enabled && (
                entry.id.toLowerCase() === requestedReward.toLowerCase()
                || entry.reward.toLowerCase() === requestedReward.toLowerCase()
            ));
            if (!catalogReward) {
                sendJSON(response, 409, { error: "This reward is no longer available." });
                return;
            }
            const points = catalogReward.points;
            const reward = catalogReward.reward;
            const requestedEmail = normalizeEmail(body.email);
            const authenticated = parseAuthenticatedCustomer(request, response, requestedEmail || null);
            if (!authenticated) {
                return;
            }

            const customer = await resolveCustomerSession(authenticated, response);
            if (!customer) {
                return;
            }

            const updated = await updateLoyaltyAccount(customer.email, (account) => {
                if (account.pointsBalance < points) {
                    throw new Error("INSUFFICIENT_POINTS");
                }

                account.pointsBalance -= points;
                account.transactions = account.transactions || [];
                const voucher = buildVoucherRecord(customer.email, reward, points);
                void storeVoucherRecord(voucher);
                account.transactions.unshift({
                    id: `txn_${Date.now()}`,
                    type: "redeem",
                    points,
                    note: reward,
                    voucherCode: voucher.code,
                    voucherDetail: voucher.detail,
                    voucherExpiresAt: voucher.expiresAt,
                    voucherSingleUse: voucher.singleUse,
                    voucherStatus: voucher.status,
                    createdAt: new Date().toISOString()
                });
            });

            if (!updated) {
                sendJSON(response, 404, { error: "Account not found" });
                return;
            }

            sendJSON(response, 200, loyaltyPayload(updated));
        } catch (error) {
            if (error.message === "INSUFFICIENT_POINTS") {
                sendJSON(response, 409, { error: "Insufficient Beans" });
                return;
            }

            sendJSON(response, 400, { error: "Invalid JSON body" });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/vouchers/consume") {
        try {
            const body = await readBody(request);
            const code = String(body.code || "").trim().toUpperCase();
            const requestedEmail = normalizeEmail(body.email);
            const authenticated = parseAuthenticatedCustomer(request, response, requestedEmail || null);
            if (!authenticated) {
                return;
            }

            const customer = await resolveCustomerSession(authenticated, response);
            if (!customer) {
                return;
            }

            if (!code) {
                sendJSON(response, 400, { error: "Missing voucher code" });
                return;
            }

            const voucher = await consumeVoucher(code, customer.email);
            sendJSON(response, 200, voucher);
        } catch (error) {
            const message = error.message || "Voucher could not be consumed";
            if (message === "VOUCHER_NOT_FOUND") {
                sendJSON(response, 404, { error: "Voucher not found" });
                return;
            }
            if (message === "VOUCHER_EMAIL_MISMATCH") {
                sendJSON(response, 403, { error: "Voucher does not belong to this account" });
                return;
            }
            if (message === "VOUCHER_ALREADY_USED") {
                sendJSON(response, 409, { error: "Voucher already used" });
                return;
            }
            if (message === "VOUCHER_EXPIRED") {
                sendJSON(response, 410, { error: "Voucher expired" });
                return;
            }

            sendJSON(response, 400, { error: "Invalid voucher payload" });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/vouchers/preview") {
        try {
            const body = await readBody(request);
            const code = String(body.code || "").trim().toUpperCase();
            const requestedEmail = normalizeEmail(body.email);
            const authenticated = parseAuthenticatedCustomer(request, response, requestedEmail || null);
            if (!authenticated) {
                return;
            }

            const customer = await resolveCustomerSession(authenticated, response);
            if (!customer) {
                return;
            }

            if (!code) {
                sendJSON(response, 400, { error: "Missing voucher code" });
                return;
            }

            const voucher = await previewVoucher(code, customer.email);
            sendJSON(response, 200, voucher);
        } catch (error) {
            const message = error.message || "Voucher could not be previewed";
            if (message === "VOUCHER_NOT_FOUND") {
                sendJSON(response, 404, { error: "Voucher not found" });
                return;
            }
            if (message === "VOUCHER_EMAIL_MISMATCH") {
                sendJSON(response, 403, { error: "Voucher does not belong to this account" });
                return;
            }
            if (message === "VOUCHER_ALREADY_USED") {
                sendJSON(response, 409, { error: "Voucher already used" });
                return;
            }
            if (message === "VOUCHER_EXPIRED") {
                sendJSON(response, 410, { error: "Voucher expired" });
                return;
            }

            sendJSON(response, 400, { error: "Invalid voucher payload" });
        }
        return;
    }

    if (request.method === "GET" && url.pathname === "/vouchers") {
        const requestedEmail = normalizeEmail(url.searchParams.get("email"));
        const authenticated = parseAuthenticatedCustomer(request, response, requestedEmail || null);
        if (!authenticated) {
            return;
        }

        const customer = await resolveCustomerSession(authenticated, response);
        if (!customer) {
            return;
        }

        sendJSON(response, 200, await activeVouchersFor(customer.email));
        return;
    }

    if (request.method === "GET") {
        try {
            const payment = await findBenefitPaymentForBrowserReturn(url);
            if (payment) {
                sendHTML(
                    response,
                    200,
                    renderBenefitResultPage(payment),
                    benefitResultPageHeaders()
                );
                return;
            }
        } catch (error) {
            console.error(
                "BENEFIT fallback return lookup failed:",
                error.code || error.message || "BENEFIT_FALLBACK_RETURN_FAILED"
            );
        }
    }

    sendJSON(response, 404, { error: "Not found" });
});
};
