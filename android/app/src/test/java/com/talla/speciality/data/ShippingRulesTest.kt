package com.talla.speciality.data

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class ShippingRulesTest {
    @Test fun bahrainHasFlatRate() {
        assertEquals(2.0, ShippingRules.rateBhd("BH", 250.0)!!, 0.0)
    }

    @Test fun gccUsesHalfKiloBands() {
        assertEquals(5.5, ShippingRules.rateBhd("SA", 500.0)!!, 0.0)
        assertEquals(6.5, ShippingRules.rateBhd("AE", 501.0)!!, 0.0)
        assertEquals(12.5, ShippingRules.rateBhd("OM", 4_000.0)!!, 0.0)
    }

    @Test fun codAddsTwoBhdInGcc() {
        assertEquals(7.5, ShippingRules.rateBhd("QA", 500.0, cashOnDelivery = true)!!, 0.0)
    }

    @Test fun invalidOrInternationalWeightUsesShopify() {
        assertNull(ShippingRules.rateBhd("SA", 4_001.0))
        assertNull(ShippingRules.rateBhd("US", 500.0))
    }
}
