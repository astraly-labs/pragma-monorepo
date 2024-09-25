/// ================== OPTIMIZATION ==================
/// Potential optimization for storage
/// instead of having `publisher_address` and `publisher_storage`, we can just have a single
/// Publisher structure struct Publisher {
///     address: ContractState,
///     sources: Array<felt25>
/// }
/// and use a single storage
/// `publisher: Map<felt252, Publisher>`
/// However, we will have to verify if it is worth it on a gas perspective

#[starknet::contract]
mod PublisherRegistry {
    use core::num::traits::Zero;
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::upgrades::{UpgradeableComponent, interface::IUpgradeable};
    use pragma_publisher_registry::{errors, interface::IPublisherRegistryABI};
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, Vec, VecTrait, MutableVecTrait,
        StoragePathEntry, Map
    };
    use starknet::{get_caller_address, ClassHash,ContractAddress};

    // ================== COMPONENTS ==================

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    // Ownable Mixin
    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    // Upgradeable
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    // ================== STORAGE ==================

    #[storage]
    struct Storage {
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        // Map between a publisher and its address( ContractAddress)
        publisher_address: Map<felt252, ContractAddress>,
        // Publisher list length
        publishers_len: u64,
        // List of registered publishers
        publishers: Vec<felt252>,
        // Length of the publisher sources
        publisher_sources_len: Map::<felt252, u64>,
        // list of sources associated to a publisher,
        publisher_sources: Map::<felt252, Vec<felt252>>,
    }

    // ================== EVENTS ==================

    #[derive(Drop, starknet::Event)]
    struct RegisteredPublisher {
        publisher: felt252,
        publisher_address: ContractAddress
    }


    #[derive(Drop, starknet::Event)]
    struct UpdatedPublisherAddress {
        publisher: felt252,
        old_publisher_address: ContractAddress,
        new_publisher_address: ContractAddress
    }

    #[derive(Drop, starknet::Event)]
    struct RemovedPublisher {
        publisher: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct DeletedSource {
        source: felt252,
    }

    #[derive(Drop, starknet::Event)]
    #[event]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        RegisteredPublisher: RegisteredPublisher,
        UpdatedPublisherAddress: UpdatedPublisherAddress,
        RemovedPublisher: RemovedPublisher,
        DeletedSource: DeletedSource
    }

    // ================== CONSTRUCTOR ================================

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        // [Check]
        assert(!owner.is_zero(), errors::OWNER_IS_ZERO);
        // [Effect]
        self.ownable.initializer(owner);
    }


    // ================== PUBLIC ABI ==================

    #[abi(embed_v0)]
    impl PublisherRegistryImpl of IPublisherRegistryABI<ContractState> {
        // @notice add a publisher to the registry
        // @dev can be called only by admin
        // @param publisher: the publisher that needs to be added
        // @param publisher_address: the address associated with the given publisher
        fn add_publisher(
            ref self: ContractState, publisher: felt252, publisher_address: ContractAddress
        ) {
            // [Check] Only owner
            self.ownable.assert_only_owner();

            // [Checks] Publisher address already registered for another publisher name
            assert(
                !self.is_address_registered(publisher_address),
                errors::ADDRESS_ALREADY_REGISTERED
            );

            // [Checks] Publisher name already registered
            let existing_publisher_address = self.get_publisher_address(publisher);
            assert(existing_publisher_address.is_zero(), errors::NAME_ALREADY_REGISTERED);

            // [Check] Publisher address is not null
            assert(!publisher_address.is_zero(), errors::CANNOT_SET_ADDRESS_TO_ZERO);

            // [Effect] Insert new publisher
            self.publishers.append().write(publisher);
            self.publishers_len.write(self.publishers_len.read() + 1);
            self.publisher_address.entry(publisher).write(publisher_address);

            // [Interaction] Event emitted
            self
                .emit(
                    Event::RegisteredPublisher(RegisteredPublisher { publisher, publisher_address })
                );
        }


        // @notice update the publisher address
        // @param publisher: the publisher whose address needs to be updated
        // @param  new_publisher_address the new publisher address
        fn update_publisher_address(
            ref self: ContractState, publisher: felt252, new_publisher_address: ContractAddress
        ) {
            // [Check] Publisher is registered
            let existing_publisher_address = self.get_publisher_address(publisher);
            assert(!existing_publisher_address.is_zero(), errors::NAME_NOT_REGISTERED);

            // [Check] Address already registered for another publisher
            assert(
                !self.is_address_registered(new_publisher_address),
                errors::ADDRESS_ALREADY_REGISTERED
            );

            // [Check] Caller is the publisher associated to the current address
            let caller = get_caller_address();
            assert(caller == existing_publisher_address, errors::CALLER_IS_NOT_PUBLISHER);

            // [Check] Publisher address is not zero
            assert(!new_publisher_address.is_zero(), errors::PUBLISHER_ADDDRESS_CANNOT_BE_ZERO);

            // [Effect] update publisher address
            self.publisher_address.entry(publisher).write(new_publisher_address);

            // [Interaction] Event emitted
            self
                .emit(
                    Event::UpdatedPublisherAddress(
                        UpdatedPublisherAddress {
                            publisher,
                            old_publisher_address: existing_publisher_address,
                            new_publisher_address
                        }
                    )
                );
        }

        // @notice remove a given publisher
        // @param publisher : the publisher that needs to be removed
        fn remove_publisher(ref self: ContractState, publisher: felt252) {
            // [Check] Only owner
            self.ownable.assert_only_owner();

            // [Check] Publisher exists
            let not_exists: bool = self.publisher_address.entry(publisher).read().is_zero();
            assert(!not_exists, errors::PUBLISHER_NOT_FOUND);

            // [Effect] Delete address (set to 0)
            self.publisher_address.entry(publisher).write(Zero::zero());

            // [Effect] Delete sources for publisher
            self.delete_sources_for_publisher(publisher);

            // [Effect] Remove the registered publisher (we are sure it's the good one due to the
            // previous check)
            if (self.publishers.len() == 1) {
                self.publishers.at(0).write(0);
                self.publishers_len.write(0);
                return ();
            }

            // [Effect] Retrieve the publisher index
            let mut publisher_idx = 0;
            match self.find_publisher_idx(publisher) {
                Option::Some(cur_idx) => publisher_idx = cur_idx,
                Option::None => panic(array![errors::PUBLISHER_NOT_FOUND])
            };
            let publishers_len = self.publishers_len.read();

            // [Effect] Remove publisher from storage
            if (publisher_idx == publishers_len - 1) {
                self.publishers_len.write(publishers_len - 1);
                self.publishers.at(publishers_len - 1).write(0);
            } else {
                let last_publisher = self.publishers.at(publishers_len - 1).read();
                self.publishers.at(publisher_idx).write(last_publisher);
                self.publishers.at(publishers_len).write(0);
                self.publishers_len.write(publishers_len - 1);
            }

            // [Interaction] Event emitted
            self.emit(Event::RemovedPublisher(RemovedPublisher { publisher, }));
        }

        // @notice add source for publisher
        // @param: the publisher for which we need to add a source
        // @param: the source that needs to be added for the given publisher
        fn add_source_for_publisher(ref self: ContractState, publisher: felt252, source: felt252) {
            // [Check] Only owner
            self.ownable.assert_only_owner();

            // [Check] Publisher existence
            let existing_publisher_address = self.get_publisher_address(publisher);
            assert(!existing_publisher_address.is_zero(), errors::PUBLISHER_NOT_FOUND);

            // [Check] Verify if the source is already available for the publisher
            let can_publish = self.can_publish_source(publisher, source);
            assert(!can_publish, errors::SOURCE_ALREADY_REGISTERED);

            // [Effect] Add new source to publisher
            self.publisher_sources.entry(publisher).append().write(source);
            self
                .publisher_sources_len
                .entry(publisher)
                .write(self.publisher_sources_len.entry(publisher).read() + 1);
        }

        // @notice add multiple sources for a publisher
        // @param the publisher for which sources needs to be added
        // @param a span of sources that needs to be added for the given publisher
        fn add_sources_for_publisher(
            ref self: ContractState, publisher: felt252, sources: Span<felt252>
        ) {
            // [Check] Only owner
            self.ownable.assert_only_owner();

            // [Effect] Add sources for publisher
            for i in 0
                ..sources
                    .len() {
                        let source = *sources.at(i);
                        self.add_source_for_publisher(publisher, source);
                    };
        }

        // @notice remove a source for a given publisher
        // @dev can be called only by the admin
        // @param  the publisher for which a source needs to be removed
        // @param source : the source that needs to be removed for the publisher
        fn remove_source_for_publisher(
            ref self: ContractState, publisher: felt252, source: felt252
        ) {
            // [Check] Only owner
            self.ownable.assert_only_owner();

            // [Check] Source list not empty
            assert(
                self.publisher_sources.entry(publisher).len() != 0, errors::NO_SOURCES_FOR_PUBLISHER
            );

            // [Effect] Retrieve the list of sources for the publisher
            let mut source_idx = 0;
            match self.find_source_idx(publisher, source) {
                Option::Some(idx) => source_idx = idx,
                Option::None => panic(array![errors::SOURCE_NOT_FOUND_FOR_PUBLISHER])
            };
            let sources_len = self.publisher_sources_len.entry(publisher).read();
            if (source_idx == sources_len - 1) {
                self.publisher_sources_len.entry(publisher).write(source_idx);
                self.publisher_sources.entry(publisher).at(source_idx).write(0);
            } else {
                let last_source = self
                    .publisher_sources
                    .entry(publisher)
                    .at(sources_len - 1)
                    .read();
                self.publisher_sources_len.entry(publisher).write(sources_len - 1);
                self.publisher_sources.entry(publisher).at(sources_len - 1).write(0);
                self.publisher_sources.entry(publisher).at(source_idx).write(last_source);
            }
            self.emit(Event::DeletedSource(DeletedSource { source, }));
        }

        // @notice remove a given source for all the publishers
        // @dev can be called only by admin
        // @param source the source to consider
        fn remove_source_for_all_publishers(ref self: ContractState, source: felt252) {
            // [Check] Only owner
            self.ownable.assert_only_owner();

            // [Effect] remove source for all publishers
            let mut publishers: Array<felt252> = self.get_all_publishers();
            loop {
                match publishers.pop_front() {
                    Option::Some(publisher) => {
                        self.remove_source_for_publisher(publisher, source);
                    },
                    Option::None(_) => { break (); }
                };
            };
            // [Interaction] Event emitted
            self.emit(Event::DeletedSource(DeletedSource { source, }));
        }

        // @notice checks whether a publisher can publish for a certain source or not
        // @param the publisher to be checked
        // @param the source to be checked
        // @returns a boolean on whether the publisher can publish for the source or not
        fn can_publish_source(self: @ContractState, publisher: felt252, source: felt252) -> bool {
            let mut found = false;
            for i in 0
                ..self
                    .publisher_sources_len
                    .entry(publisher)
                    .read() {
                        if (self.publisher_sources.entry(publisher).at(i).read() == source) {
                            found = true;
                            break;
                        }
                    };
            found
        }

        // @notice  get the publisher address
        // @param the publisher from which we want to retrieve the address
        // @returns the address associated to the given publisher
        fn get_publisher_address(self: @ContractState, publisher: felt252) -> ContractAddress {
            self.publisher_address.entry(publisher).read()
        }


        // @notice retrieve all the publishers
        // @returns an array of publishers
        fn get_all_publishers(self: @ContractState) -> Array<felt252> {
            let mut publishers = array![];
            for i in 0
                ..self.publishers_len.read() {
                    publishers.append(self.publishers.at(i).read());
                };
            publishers
        }


        // @notice retrieve all the allowed sources for a given publisher
        // @param publisher : the publisher
        // @returns an array of sources
        fn get_publisher_sources(self: @ContractState, publisher: felt252) -> Array<felt252> {
            let mut sources = array![];
            for i in 0
                ..self
                    .publisher_sources_len
                    .entry(publisher)
                    .read() {
                        sources.append(self.publisher_sources.entry(publisher).at(i).read());
                    };
            sources
        }
    }

    // ================== COMPONENTS IMPLEMENTATIONS ==================

    // Upgradeable impl
    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            // [Check] Only owner
            self.ownable.assert_only_owner();
            // [Effect] Upgrade contract
            self.upgradeable.upgrade(new_class_hash);
        }
    }

    // ================== PRIVATE IMPLEMENTATIONS ==================
    #[generate_trait]
    impl InternalFunctions of InternalFunctionsTrait {
        fn get_n_th_publisher_source(
            self: @ContractState, publisher: felt252, index: u64
        ) -> Option<felt252> {
            if let Option::Some(storage_ptr) = self.publisher_sources.entry(publisher).get(index) {
                return Option::Some(storage_ptr.read());
            }
            return Option::None;
        }

        fn delete_sources_for_publisher(ref self: ContractState, publisher: felt252) {
            self.publisher_sources_len.entry(publisher).write(0);
            self.publisher_sources.entry(publisher).at(0).write(0);
        }

        fn delete_source_for_publisher(
            ref self: ContractState, publisher: felt252, source: felt252
        ) {}


        
        fn find_publisher_idx(self: @ContractState, publisher: felt252) -> Option<u64> {
            let mut cur_idx = 0;
            loop {
                if (cur_idx == self.publishers_len.read()) {
                    break (Option::None);
                }
                if (self.publishers.at(cur_idx).read() == publisher) {
                    break (Option::Some(cur_idx));
                }
                cur_idx += 1;
            }
        }

        fn find_source_idx(
            self: @ContractState, publisher: felt252, source: felt252
        ) -> Option<u64> {
            let mut cur_idx = 0;
            if self.publisher_sources.entry(publisher).len() == 0 {
                return Option::None;
            }
            loop {
                if (cur_idx == self.publisher_sources_len.entry(publisher).read()) {
                    break (Option::None);
                }
                if (self.get_n_th_publisher_source(publisher, cur_idx).unwrap() == source) {
                    break (Option::Some(cur_idx));
                }
                cur_idx += 1;
            }
        }

        fn is_address_registered(self: @ContractState, address: ContractAddress) -> bool {
            let mut cur_idx = 0;
            let mut boolean = false;
            loop {
                if (cur_idx == self.publishers.len()) {
                    break ();
                }
                let publisher = self.publishers.at(cur_idx).read();
                let publisher_address = self.publisher_address.entry(publisher).read();
                if (publisher_address == address) {
                    boolean = true;
                    break ();
                }
                cur_idx += 1;
            };
            boolean
        }
    }
}
