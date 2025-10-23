module suilend::test_dynamic_field {
    use sui::dynamic_field as df;
    use sui::test_scenario;
    use sui::test_utils::{destroy};

    // Define a simple struct to hold a dynamic field
    public struct Container has key {
        id: UID,
    }

    // Utility function to create a Container with a dynamic field
    public fun create_container_with_field(ctx: &mut TxContext): Container {
        let mut container = Container {
            id: object::new(ctx),
        };
        df::add(&mut container.id, b"field_key", 42u64); // Add a dynamic field with value 42
        container
    }

    #[test]
    fun test_one() {
        let mut scenario = test_scenario::begin(@0x1);
        let ctx = test_scenario::ctx(&mut scenario);
        let container = create_container_with_field(ctx);
        
        // Verify the dynamic field exists and has the correct value
        assert!(df::exists_(&container.id, b"field_key"));
        let value: &u64 = df::borrow(&container.id, b"field_key");
        assert!(*value == 42);

        destroy(container);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_two() {
        let mut scenario = test_scenario::begin(@0x1);
        let ctx = test_scenario::ctx(&mut scenario);
        let container = create_container_with_field(ctx);
        
        // Verify the dynamic field exists and has the correct value
        assert!(df::exists_(&container.id, b"field_key"));
        let value: &u64 = df::borrow(&container.id, b"field_key");
        assert!(*value == 42);

        destroy(container);
        test_scenario::end(scenario);
    }
}
