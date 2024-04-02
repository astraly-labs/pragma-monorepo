#[allow(dead_code, unused_imports, non_camel_case_types)]
#[allow(clippy::all)]
#[allow(rustdoc::broken_intra_doc_links)]
pub mod api {
    #[allow(unused_imports)]
    mod root_mod {
        pub use super::*;
    }
    pub static PALLETS: [&str; 6usize] = ["System", "Timestamp", "Aura", "Grandpa", "Starknet", "Autonomous"];
    pub static RUNTIME_APIS: [&str; 11usize] = [
        "Core",
        "Metadata",
        "BlockBuilder",
        "TaggedTransactionQueue",
        "OffchainWorkerApi",
        "AuraApi",
        "SessionKeys",
        "GrandpaApi",
        "AccountNonceApi",
        "StarknetRuntimeApi",
        "ConvertTransactionRuntimeApi",
    ];
    #[doc = r" The error type returned when there is a runtime issue."]
    pub type DispatchError = runtime_types::sp_runtime::DispatchError;
    #[doc = r" The outer event enum."]
    pub type Event = runtime_types::madara_runtime::RuntimeEvent;
    #[doc = r" The outer extrinsic enum."]
    pub type Call = runtime_types::madara_runtime::RuntimeCall;
    #[doc = r" The outer error enum representing the DispatchError's Module variant."]
    pub type Error = runtime_types::madara_runtime::RuntimeError;
    pub fn constants() -> ConstantsApi {
        ConstantsApi
    }
    pub fn storage() -> StorageApi {
        StorageApi
    }
    pub fn tx() -> TransactionApi {
        TransactionApi
    }
    pub fn apis() -> runtime_apis::RuntimeApi {
        runtime_apis::RuntimeApi
    }
    pub mod runtime_apis {
        use super::root_mod;
        use super::runtime_types;
        use ::subxt::ext::codec::Encode;
        pub struct RuntimeApi;
        impl RuntimeApi {
            pub fn core(&self) -> core::Core {
                core::Core
            }
            pub fn metadata(&self) -> metadata::Metadata {
                metadata::Metadata
            }
            pub fn block_builder(&self) -> block_builder::BlockBuilder {
                block_builder::BlockBuilder
            }
            pub fn tagged_transaction_queue(&self) -> tagged_transaction_queue::TaggedTransactionQueue {
                tagged_transaction_queue::TaggedTransactionQueue
            }
            pub fn offchain_worker_api(&self) -> offchain_worker_api::OffchainWorkerApi {
                offchain_worker_api::OffchainWorkerApi
            }
            pub fn aura_api(&self) -> aura_api::AuraApi {
                aura_api::AuraApi
            }
            pub fn session_keys(&self) -> session_keys::SessionKeys {
                session_keys::SessionKeys
            }
            pub fn grandpa_api(&self) -> grandpa_api::GrandpaApi {
                grandpa_api::GrandpaApi
            }
            pub fn account_nonce_api(&self) -> account_nonce_api::AccountNonceApi {
                account_nonce_api::AccountNonceApi
            }
            pub fn starknet_runtime_api(&self) -> starknet_runtime_api::StarknetRuntimeApi {
                starknet_runtime_api::StarknetRuntimeApi
            }
            pub fn convert_transaction_runtime_api(
                &self,
            ) -> convert_transaction_runtime_api::ConvertTransactionRuntimeApi {
                convert_transaction_runtime_api::ConvertTransactionRuntimeApi
            }
        }
        pub mod core {
            use super::root_mod;
            use super::runtime_types;
            #[doc = " The `Core` runtime api that every Substrate runtime needs to implement."]
            pub struct Core;
            impl Core {
                #[doc = " Returns the version of the runtime."]
                pub fn version(&self) -> ::subxt::runtime_api::Payload<types::Version, types::version::output::Output> {
                    ::subxt::runtime_api::Payload::new_static(
                        "Core",
                        "version",
                        types::Version {},
                        [
                            76u8, 202u8, 17u8, 117u8, 189u8, 237u8, 239u8, 237u8, 151u8, 17u8, 125u8, 159u8, 218u8,
                            92u8, 57u8, 238u8, 64u8, 147u8, 40u8, 72u8, 157u8, 116u8, 37u8, 195u8, 156u8, 27u8, 123u8,
                            173u8, 178u8, 102u8, 136u8, 6u8,
                        ],
                    )
                }
                #[doc = " Execute the given block."]
                pub fn execute_block(
                    &self,
                    block: types::execute_block::Block,
                ) -> ::subxt::runtime_api::Payload<types::ExecuteBlock, types::execute_block::output::Output>
                {
                    ::subxt::runtime_api::Payload::new_static(
                        "Core",
                        "execute_block",
                        types::ExecuteBlock { block },
                        [
                            133u8, 135u8, 228u8, 65u8, 106u8, 27u8, 85u8, 158u8, 112u8, 254u8, 93u8, 26u8, 102u8,
                            201u8, 118u8, 216u8, 249u8, 247u8, 91u8, 74u8, 56u8, 208u8, 231u8, 115u8, 131u8, 29u8,
                            209u8, 6u8, 65u8, 57u8, 214u8, 125u8,
                        ],
                    )
                }
                #[doc = " Initialize a block with the given header."]
                pub fn initialize_block(
                    &self,
                    header: types::initialize_block::Header,
                ) -> ::subxt::runtime_api::Payload<types::InitializeBlock, types::initialize_block::output::Output>
                {
                    ::subxt::runtime_api::Payload::new_static(
                        "Core",
                        "initialize_block",
                        types::InitializeBlock { header },
                        [
                            146u8, 138u8, 72u8, 240u8, 63u8, 96u8, 110u8, 189u8, 77u8, 92u8, 96u8, 232u8, 41u8, 217u8,
                            105u8, 148u8, 83u8, 190u8, 152u8, 219u8, 19u8, 87u8, 163u8, 1u8, 232u8, 25u8, 221u8, 74u8,
                            224u8, 67u8, 223u8, 34u8,
                        ],
                    )
                }
            }
            pub mod types {
                use super::runtime_types;
                pub mod version {
                    use super::runtime_types;
                    pub mod output {
                        use super::runtime_types;
                        pub type Output = runtime_types::sp_version::RuntimeVersion;
                    }
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct Version {}
                pub mod execute_block {
                    use super::runtime_types;
                    pub type Block = runtime_types::sp_runtime::generic::block::Block<
                        runtime_types::sp_runtime::generic::header::Header<::core::primitive::u32>,
                        ::subxt::utils::UncheckedExtrinsic<
                            ::subxt::utils::MultiAddress<::subxt::utils::AccountId32, ()>,
                            runtime_types::madara_runtime::RuntimeCall,
                            runtime_types::sp_runtime::MultiSignature,
                            (
                                runtime_types::frame_system::extensions::check_non_zero_sender::CheckNonZeroSender,
                                runtime_types::frame_system::extensions::check_spec_version::CheckSpecVersion,
                                runtime_types::frame_system::extensions::check_tx_version::CheckTxVersion,
                                runtime_types::frame_system::extensions::check_genesis::CheckGenesis,
                                runtime_types::frame_system::extensions::check_mortality::CheckMortality,
                                runtime_types::frame_system::extensions::check_nonce::CheckNonce,
                                runtime_types::frame_system::extensions::check_weight::CheckWeight,
                            ),
                        >,
                    >;
                    pub mod output {
                        use super::runtime_types;
                        pub type Output = ();
                    }
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct ExecuteBlock {
                    pub block: execute_block::Block,
                }
                pub mod initialize_block {
                    use super::runtime_types;
                    pub type Header = runtime_types::sp_runtime::generic::header::Header<::core::primitive::u32>;
                    pub mod output {
                        use super::runtime_types;
                        pub type Output = ();
                    }
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct InitializeBlock {
                    pub header: initialize_block::Header,
                }
            }
        }
        pub mod metadata {
            use super::root_mod;
            use super::runtime_types;
            #[doc = " The `Metadata` api trait that returns metadata for the runtime."]
            pub struct Metadata;
            impl Metadata {
                #[doc = " Returns the metadata of a runtime."]
                pub fn metadata(
                    &self,
                ) -> ::subxt::runtime_api::Payload<types::Metadata, types::metadata::output::Output> {
                    ::subxt::runtime_api::Payload::new_static(
                        "Metadata",
                        "metadata",
                        types::Metadata {},
                        [
                            231u8, 24u8, 67u8, 152u8, 23u8, 26u8, 188u8, 82u8, 229u8, 6u8, 185u8, 27u8, 175u8, 68u8,
                            83u8, 122u8, 69u8, 89u8, 185u8, 74u8, 248u8, 87u8, 217u8, 124u8, 193u8, 252u8, 199u8,
                            186u8, 196u8, 179u8, 179u8, 96u8,
                        ],
                    )
                }
                #[doc = " Returns the metadata at a given version."]
                #[doc = ""]
                #[doc = " If the given `version` isn't supported, this will return `None`."]
                #[doc = " Use [`Self::metadata_versions`] to find out about supported metadata version of the runtime."]
                pub fn metadata_at_version(
                    &self,
                    version: types::metadata_at_version::Version,
                ) -> ::subxt::runtime_api::Payload<types::MetadataAtVersion, types::metadata_at_version::output::Output>
                {
                    ::subxt::runtime_api::Payload::new_static(
                        "Metadata",
                        "metadata_at_version",
                        types::MetadataAtVersion { version },
                        [
                            131u8, 53u8, 212u8, 234u8, 16u8, 25u8, 120u8, 252u8, 153u8, 153u8, 216u8, 28u8, 54u8,
                            113u8, 52u8, 236u8, 146u8, 68u8, 142u8, 8u8, 10u8, 169u8, 131u8, 142u8, 204u8, 38u8, 48u8,
                            108u8, 134u8, 86u8, 226u8, 61u8,
                        ],
                    )
                }
                #[doc = " Returns the supported metadata versions."]
                #[doc = ""]
                #[doc = " This can be used to call `metadata_at_version`."]
                pub fn metadata_versions(
                    &self,
                ) -> ::subxt::runtime_api::Payload<types::MetadataVersions, types::metadata_versions::output::Output>
                {
                    ::subxt::runtime_api::Payload::new_static(
                        "Metadata",
                        "metadata_versions",
                        types::MetadataVersions {},
                        [
                            23u8, 144u8, 137u8, 91u8, 188u8, 39u8, 231u8, 208u8, 252u8, 218u8, 224u8, 176u8, 77u8,
                            32u8, 130u8, 212u8, 223u8, 76u8, 100u8, 190u8, 82u8, 94u8, 190u8, 8u8, 82u8, 244u8, 225u8,
                            179u8, 85u8, 176u8, 56u8, 16u8,
                        ],
                    )
                }
            }
            pub mod types {
                use super::runtime_types;
                pub mod metadata {
                    use super::runtime_types;
                    pub mod output {
                        use super::runtime_types;
                        pub type Output = runtime_types::sp_core::OpaqueMetadata;
                    }
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct Metadata {}
                pub mod metadata_at_version {
                    use super::runtime_types;
                    pub type Version = ::core::primitive::u32;
                    pub mod output {
                        use super::runtime_types;
                        pub type Output = ::core::option::Option<runtime_types::sp_core::OpaqueMetadata>;
                    }
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct MetadataAtVersion {
                    pub version: metadata_at_version::Version,
                }
                pub mod metadata_versions {
                    use super::runtime_types;
                    pub mod output {
                        use super::runtime_types;
                        pub type Output = ::std::vec::Vec<::core::primitive::u32>;
                    }
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct MetadataVersions {}
            }
        }
        pub mod block_builder {
            use super::root_mod;
            use super::runtime_types;
            #[doc = " The `BlockBuilder` api trait that provides the required functionality for building a block."]
            pub struct BlockBuilder;
            impl BlockBuilder {
                #[doc = " Apply the given extrinsic."]
                #[doc = ""]
                #[doc = " Returns an inclusion outcome which specifies if this extrinsic is included in"]
                #[doc = " this block or not."]
                pub fn apply_extrinsic(
                    &self,
                    extrinsic: types::apply_extrinsic::Extrinsic,
                ) -> ::subxt::runtime_api::Payload<types::ApplyExtrinsic, types::apply_extrinsic::output::Output>
                {
                    ::subxt::runtime_api::Payload::new_static(
                        "BlockBuilder",
                        "apply_extrinsic",
                        types::ApplyExtrinsic { extrinsic },
                        [
                            72u8, 54u8, 139u8, 3u8, 118u8, 136u8, 65u8, 47u8, 6u8, 105u8, 125u8, 223u8, 160u8, 29u8,
                            103u8, 74u8, 79u8, 149u8, 48u8, 90u8, 237u8, 2u8, 97u8, 201u8, 123u8, 34u8, 167u8, 37u8,
                            187u8, 35u8, 176u8, 97u8,
                        ],
                    )
                }
                #[doc = " Finish the current block."]
                pub fn finalize_block(
                    &self,
                ) -> ::subxt::runtime_api::Payload<types::FinalizeBlock, types::finalize_block::output::Output>
                {
                    ::subxt::runtime_api::Payload::new_static(
                        "BlockBuilder",
                        "finalize_block",
                        types::FinalizeBlock {},
                        [
                            244u8, 207u8, 24u8, 33u8, 13u8, 69u8, 9u8, 249u8, 145u8, 143u8, 122u8, 96u8, 197u8, 55u8,
                            64u8, 111u8, 238u8, 224u8, 34u8, 201u8, 27u8, 146u8, 232u8, 99u8, 191u8, 30u8, 114u8, 16u8,
                            32u8, 220u8, 58u8, 62u8,
                        ],
                    )
                }
                #[doc = " Generate inherent extrinsics. The inherent data will vary from chain to chain."]
                pub fn inherent_extrinsics(
                    &self,
                    inherent: types::inherent_extrinsics::Inherent,
                ) -> ::subxt::runtime_api::Payload<types::InherentExtrinsics, types::inherent_extrinsics::output::Output>
                {
                    ::subxt::runtime_api::Payload::new_static(
                        "BlockBuilder",
                        "inherent_extrinsics",
                        types::InherentExtrinsics { inherent },
                        [
                            254u8, 110u8, 245u8, 201u8, 250u8, 192u8, 27u8, 228u8, 151u8, 213u8, 166u8, 89u8, 94u8,
                            81u8, 189u8, 234u8, 64u8, 18u8, 245u8, 80u8, 29u8, 18u8, 140u8, 129u8, 113u8, 236u8, 135u8,
                            55u8, 79u8, 159u8, 175u8, 183u8,
                        ],
                    )
                }
                #[doc = " Check that the inherents are valid. The inherent data will vary from chain to chain."]
                pub fn check_inherents(
                    &self,
                    block: types::check_inherents::Block,
                    data: types::check_inherents::Data,
                ) -> ::subxt::runtime_api::Payload<types::CheckInherents, types::check_inherents::output::Output>
                {
                    ::subxt::runtime_api::Payload::new_static(
                        "BlockBuilder",
                        "check_inherents",
                        types::CheckInherents { block, data },
                        [
                            153u8, 134u8, 1u8, 215u8, 139u8, 11u8, 53u8, 51u8, 210u8, 175u8, 197u8, 28u8, 38u8, 209u8,
                            175u8, 247u8, 142u8, 157u8, 50u8, 151u8, 164u8, 191u8, 181u8, 118u8, 80u8, 97u8, 160u8,
                            248u8, 110u8, 217u8, 181u8, 234u8,
                        ],
                    )
                }
            }
            pub mod types {
                use super::runtime_types;
                pub mod apply_extrinsic {
                    use super::runtime_types;
                    pub type Extrinsic = ::subxt::utils::UncheckedExtrinsic<
                        ::subxt::utils::MultiAddress<::subxt::utils::AccountId32, ()>,
                        runtime_types::madara_runtime::RuntimeCall,
                        runtime_types::sp_runtime::MultiSignature,
                        (
                            runtime_types::frame_system::extensions::check_non_zero_sender::CheckNonZeroSender,
                            runtime_types::frame_system::extensions::check_spec_version::CheckSpecVersion,
                            runtime_types::frame_system::extensions::check_tx_version::CheckTxVersion,
                            runtime_types::frame_system::extensions::check_genesis::CheckGenesis,
                            runtime_types::frame_system::extensions::check_mortality::CheckMortality,
                            runtime_types::frame_system::extensions::check_nonce::CheckNonce,
                            runtime_types::frame_system::extensions::check_weight::CheckWeight,
                        ),
                    >;
                    pub mod output {
                        use super::runtime_types;
                        pub type Output = ::core::result::Result<
                            ::core::result::Result<(), runtime_types::sp_runtime::DispatchError>,
                            runtime_types::sp_runtime::transaction_validity::TransactionValidityError,
                        >;
                    }
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct ApplyExtrinsic {
                    pub extrinsic: apply_extrinsic::Extrinsic,
                }
                pub mod finalize_block {
                    use super::runtime_types;
                    pub mod output {
                        use super::runtime_types;
                        pub type Output = runtime_types::sp_runtime::generic::header::Header<::core::primitive::u32>;
                    }
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct FinalizeBlock {}
                pub mod inherent_extrinsics {
                    use super::runtime_types;
                    pub type Inherent = runtime_types::sp_inherents::InherentData;
                    pub mod output {
                        use super::runtime_types;
                        pub type Output = ::std::vec::Vec<
                            ::subxt::utils::UncheckedExtrinsic<
                                ::subxt::utils::MultiAddress<::subxt::utils::AccountId32, ()>,
                                runtime_types::madara_runtime::RuntimeCall,
                                runtime_types::sp_runtime::MultiSignature,
                                (
                                    runtime_types::frame_system::extensions::check_non_zero_sender::CheckNonZeroSender,
                                    runtime_types::frame_system::extensions::check_spec_version::CheckSpecVersion,
                                    runtime_types::frame_system::extensions::check_tx_version::CheckTxVersion,
                                    runtime_types::frame_system::extensions::check_genesis::CheckGenesis,
                                    runtime_types::frame_system::extensions::check_mortality::CheckMortality,
                                    runtime_types::frame_system::extensions::check_nonce::CheckNonce,
                                    runtime_types::frame_system::extensions::check_weight::CheckWeight,
                                ),
                            >,
                        >;
                    }
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct InherentExtrinsics {
                    pub inherent: inherent_extrinsics::Inherent,
                }
                pub mod check_inherents {
                    use super::runtime_types;
                    pub type Block = runtime_types::sp_runtime::generic::block::Block<
                        runtime_types::sp_runtime::generic::header::Header<::core::primitive::u32>,
                        ::subxt::utils::UncheckedExtrinsic<
                            ::subxt::utils::MultiAddress<::subxt::utils::AccountId32, ()>,
                            runtime_types::madara_runtime::RuntimeCall,
                            runtime_types::sp_runtime::MultiSignature,
                            (
                                runtime_types::frame_system::extensions::check_non_zero_sender::CheckNonZeroSender,
                                runtime_types::frame_system::extensions::check_spec_version::CheckSpecVersion,
                                runtime_types::frame_system::extensions::check_tx_version::CheckTxVersion,
                                runtime_types::frame_system::extensions::check_genesis::CheckGenesis,
                                runtime_types::frame_system::extensions::check_mortality::CheckMortality,
                                runtime_types::frame_system::extensions::check_nonce::CheckNonce,
                                runtime_types::frame_system::extensions::check_weight::CheckWeight,
                            ),
                        >,
                    >;
                    pub type Data = runtime_types::sp_inherents::InherentData;
                    pub mod output {
                        use super::runtime_types;
                        pub type Output = runtime_types::sp_inherents::CheckInherentsResult;
                    }
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct CheckInherents {
                    pub block: check_inherents::Block,
                    pub data: check_inherents::Data,
                }
            }
        }
        pub mod tagged_transaction_queue {
            use super::root_mod;
            use super::runtime_types;
            #[doc = " The `TaggedTransactionQueue` api trait for interfering with the transaction queue."]
            pub struct TaggedTransactionQueue;
            impl TaggedTransactionQueue {
                #[doc = " Validate the transaction."]
                #[doc = ""]
                #[doc = " This method is invoked by the transaction pool to learn details about given transaction."]
                #[doc = " The implementation should make sure to verify the correctness of the transaction"]
                #[doc = " against current state. The given `block_hash` corresponds to the hash of the block"]
                #[doc = " that is used as current state."]
                #[doc = ""]
                #[doc = " Note that this call may be performed by the pool multiple times and transactions"]
                #[doc = " might be verified in any possible order."]
                pub fn validate_transaction(
                    &self,
                    source: types::validate_transaction::Source,
                    tx: types::validate_transaction::Tx,
                    block_hash: types::validate_transaction::BlockHash,
                ) -> ::subxt::runtime_api::Payload<
                    types::ValidateTransaction,
                    types::validate_transaction::output::Output,
                > {
                    ::subxt::runtime_api::Payload::new_static(
                        "TaggedTransactionQueue",
                        "validate_transaction",
                        types::ValidateTransaction { source, tx, block_hash },
                        [
                            196u8, 50u8, 90u8, 49u8, 109u8, 251u8, 200u8, 35u8, 23u8, 150u8, 140u8, 143u8, 232u8,
                            164u8, 133u8, 89u8, 32u8, 240u8, 115u8, 39u8, 95u8, 70u8, 162u8, 76u8, 122u8, 73u8, 151u8,
                            144u8, 234u8, 120u8, 100u8, 29u8,
                        ],
                    )
                }
            }
            pub mod types {
                use super::runtime_types;
                pub mod validate_transaction {
                    use super::runtime_types;
                    pub type Source = runtime_types::sp_runtime::transaction_validity::TransactionSource;
                    pub type Tx = ::subxt::utils::UncheckedExtrinsic<
                        ::subxt::utils::MultiAddress<::subxt::utils::AccountId32, ()>,
                        runtime_types::madara_runtime::RuntimeCall,
                        runtime_types::sp_runtime::MultiSignature,
                        (
                            runtime_types::frame_system::extensions::check_non_zero_sender::CheckNonZeroSender,
                            runtime_types::frame_system::extensions::check_spec_version::CheckSpecVersion,
                            runtime_types::frame_system::extensions::check_tx_version::CheckTxVersion,
                            runtime_types::frame_system::extensions::check_genesis::CheckGenesis,
                            runtime_types::frame_system::extensions::check_mortality::CheckMortality,
                            runtime_types::frame_system::extensions::check_nonce::CheckNonce,
                            runtime_types::frame_system::extensions::check_weight::CheckWeight,
                        ),
                    >;
                    pub type BlockHash = ::subxt::utils::H256;
                    pub mod output {
                        use super::runtime_types;
                        pub type Output = ::core::result::Result<
                            runtime_types::sp_runtime::transaction_validity::ValidTransaction,
                            runtime_types::sp_runtime::transaction_validity::TransactionValidityError,
                        >;
                    }
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct ValidateTransaction {
                    pub source: validate_transaction::Source,
                    pub tx: validate_transaction::Tx,
                    pub block_hash: validate_transaction::BlockHash,
                }
            }
        }
        pub mod offchain_worker_api {
            use super::root_mod;
            use super::runtime_types;
            #[doc = " The offchain worker api."]
            pub struct OffchainWorkerApi;
            impl OffchainWorkerApi {
                #[doc = " Starts the off-chain task for given block header."]
                pub fn offchain_worker(
                    &self,
                    header: types::offchain_worker::Header,
                ) -> ::subxt::runtime_api::Payload<types::OffchainWorker, types::offchain_worker::output::Output>
                {
                    ::subxt::runtime_api::Payload::new_static(
                        "OffchainWorkerApi",
                        "offchain_worker",
                        types::OffchainWorker { header },
                        [
                            10u8, 135u8, 19u8, 153u8, 33u8, 216u8, 18u8, 242u8, 33u8, 140u8, 4u8, 223u8, 200u8, 130u8,
                            103u8, 118u8, 137u8, 24u8, 19u8, 127u8, 161u8, 29u8, 184u8, 111u8, 222u8, 111u8, 253u8,
                            73u8, 45u8, 31u8, 79u8, 60u8,
                        ],
                    )
                }
            }
            pub mod types {
                use super::runtime_types;
                pub mod offchain_worker {
                    use super::runtime_types;
                    pub type Header = runtime_types::sp_runtime::generic::header::Header<::core::primitive::u32>;
                    pub mod output {
                        use super::runtime_types;
                        pub type Output = ();
                    }
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct OffchainWorker {
                    pub header: offchain_worker::Header,
                }
            }
        }
        pub mod aura_api {
            use super::root_mod;
            use super::runtime_types;
            #[doc = " API necessary for block authorship with aura."]
            pub struct AuraApi;
            impl AuraApi {
                #[doc = " Returns the slot duration for Aura."]
                #[doc = ""]
                #[doc = " Currently, only the value provided by this type at genesis will be used."]
                pub fn slot_duration(
                    &self,
                ) -> ::subxt::runtime_api::Payload<types::SlotDuration, types::slot_duration::output::Output>
                {
                    ::subxt::runtime_api::Payload::new_static(
                        "AuraApi",
                        "slot_duration",
                        types::SlotDuration {},
                        [
                            233u8, 210u8, 132u8, 172u8, 100u8, 125u8, 239u8, 92u8, 114u8, 82u8, 7u8, 110u8, 179u8,
                            196u8, 10u8, 19u8, 211u8, 15u8, 174u8, 2u8, 91u8, 73u8, 133u8, 100u8, 205u8, 201u8, 191u8,
                            60u8, 163u8, 122u8, 215u8, 10u8,
                        ],
                    )
                }
                #[doc = " Return the current set of authorities."]
                pub fn authorities(
                    &self,
                ) -> ::subxt::runtime_api::Payload<types::Authorities, types::authorities::output::Output>
                {
                    ::subxt::runtime_api::Payload::new_static(
                        "AuraApi",
                        "authorities",
                        types::Authorities {},
                        [
                            96u8, 136u8, 226u8, 244u8, 105u8, 189u8, 8u8, 250u8, 71u8, 230u8, 37u8, 123u8, 218u8, 47u8,
                            179u8, 16u8, 170u8, 181u8, 165u8, 77u8, 102u8, 51u8, 43u8, 51u8, 186u8, 84u8, 49u8, 15u8,
                            208u8, 226u8, 129u8, 230u8,
                        ],
                    )
                }
            }
            pub mod types {
                use super::runtime_types;
                pub mod slot_duration {
                    use super::runtime_types;
                    pub mod output {
                        use super::runtime_types;
                        pub type Output = runtime_types::sp_consensus_slots::SlotDuration;
                    }
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct SlotDuration {}
                pub mod authorities {
                    use super::runtime_types;
                    pub mod output {
                        use super::runtime_types;
                        pub type Output =
                            ::std::vec::Vec<runtime_types::sp_consensus_aura::sr25519::app_sr25519::Public>;
                    }
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct Authorities {}
            }
        }
        pub mod session_keys {
            use super::root_mod;
            use super::runtime_types;
            #[doc = " Session keys runtime api."]
            pub struct SessionKeys;
            impl SessionKeys {
                #[doc = " Generate a set of session keys with optionally using the given seed."]
                #[doc = " The keys should be stored within the keystore exposed via runtime"]
                #[doc = " externalities."]
                #[doc = ""]
                #[doc = " The seed needs to be a valid `utf8` string."]
                #[doc = ""]
                #[doc = " Returns the concatenated SCALE encoded public keys."]
                pub fn generate_session_keys(
                    &self,
                    seed: types::generate_session_keys::Seed,
                ) -> ::subxt::runtime_api::Payload<
                    types::GenerateSessionKeys,
                    types::generate_session_keys::output::Output,
                > {
                    ::subxt::runtime_api::Payload::new_static(
                        "SessionKeys",
                        "generate_session_keys",
                        types::GenerateSessionKeys { seed },
                        [
                            96u8, 171u8, 164u8, 166u8, 175u8, 102u8, 101u8, 47u8, 133u8, 95u8, 102u8, 202u8, 83u8,
                            26u8, 238u8, 47u8, 126u8, 132u8, 22u8, 11u8, 33u8, 190u8, 175u8, 94u8, 58u8, 245u8, 46u8,
                            80u8, 195u8, 184u8, 107u8, 65u8,
                        ],
                    )
                }
                #[doc = " Decode the given public session keys."]
                #[doc = ""]
                #[doc = " Returns the list of public raw public keys + key type."]
                pub fn decode_session_keys(
                    &self,
                    encoded: types::decode_session_keys::Encoded,
                ) -> ::subxt::runtime_api::Payload<types::DecodeSessionKeys, types::decode_session_keys::output::Output>
                {
                    ::subxt::runtime_api::Payload::new_static(
                        "SessionKeys",
                        "decode_session_keys",
                        types::DecodeSessionKeys { encoded },
                        [
                            57u8, 242u8, 18u8, 51u8, 132u8, 110u8, 238u8, 255u8, 39u8, 194u8, 8u8, 54u8, 198u8, 178u8,
                            75u8, 151u8, 148u8, 176u8, 144u8, 197u8, 87u8, 29u8, 179u8, 235u8, 176u8, 78u8, 252u8,
                            103u8, 72u8, 203u8, 151u8, 248u8,
                        ],
                    )
                }
            }
            pub mod types {
                use super::runtime_types;
                pub mod generate_session_keys {
                    use super::runtime_types;
                    pub type Seed = ::core::option::Option<::std::vec::Vec<::core::primitive::u8>>;
                    pub mod output {
                        use super::runtime_types;
                        pub type Output = ::std::vec::Vec<::core::primitive::u8>;
                    }
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct GenerateSessionKeys {
                    pub seed: generate_session_keys::Seed,
                }
                pub mod decode_session_keys {
                    use super::runtime_types;
                    pub type Encoded = ::std::vec::Vec<::core::primitive::u8>;
                    pub mod output {
                        use super::runtime_types;
                        pub type Output = ::core::option::Option<
                            ::std::vec::Vec<(
                                ::std::vec::Vec<::core::primitive::u8>,
                                runtime_types::sp_core::crypto::KeyTypeId,
                            )>,
                        >;
                    }
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct DecodeSessionKeys {
                    pub encoded: decode_session_keys::Encoded,
                }
            }
        }
        pub mod grandpa_api {
            use super::root_mod;
            use super::runtime_types;
            #[doc = " APIs for integrating the GRANDPA finality gadget into runtimes."]
            #[doc = " This should be implemented on the runtime side."]
            #[doc = ""]
            #[doc = " This is primarily used for negotiating authority-set changes for the"]
            #[doc = " gadget. GRANDPA uses a signaling model of changing authority sets:"]
            #[doc = " changes should be signaled with a delay of N blocks, and then automatically"]
            #[doc = " applied in the runtime after those N blocks have passed."]
            #[doc = ""]
            #[doc = " The consensus protocol will coordinate the handoff externally."]
            pub struct GrandpaApi;
            impl GrandpaApi {
                #[doc = " Get the current GRANDPA authorities and weights. This should not change except"]
                #[doc = " for when changes are scheduled and the corresponding delay has passed."]
                #[doc = ""]
                #[doc = " When called at block B, it will return the set of authorities that should be"]
                #[doc = " used to finalize descendants of this block (B+1, B+2, ...). The block B itself"]
                #[doc = " is finalized by the authorities from block B-1."]
                pub fn grandpa_authorities(
                    &self,
                ) -> ::subxt::runtime_api::Payload<types::GrandpaAuthorities, types::grandpa_authorities::output::Output>
                {
                    ::subxt::runtime_api::Payload::new_static(
                        "GrandpaApi",
                        "grandpa_authorities",
                        types::GrandpaAuthorities {},
                        [
                            166u8, 76u8, 160u8, 101u8, 242u8, 145u8, 213u8, 10u8, 16u8, 130u8, 230u8, 196u8, 125u8,
                            152u8, 92u8, 143u8, 119u8, 223u8, 140u8, 189u8, 203u8, 95u8, 52u8, 105u8, 147u8, 107u8,
                            135u8, 228u8, 62u8, 178u8, 128u8, 33u8,
                        ],
                    )
                }
                #[doc = " Submits an unsigned extrinsic to report an equivocation. The caller"]
                #[doc = " must provide the equivocation proof and a key ownership proof"]
                #[doc = " (should be obtained using `generate_key_ownership_proof`). The"]
                #[doc = " extrinsic will be unsigned and should only be accepted for local"]
                #[doc = " authorship (not to be broadcast to the network). This method returns"]
                #[doc = " `None` when creation of the extrinsic fails, e.g. if equivocation"]
                #[doc = " reporting is disabled for the given runtime (i.e. this method is"]
                #[doc = " hardcoded to return `None`). Only useful in an offchain context."]
                pub fn submit_report_equivocation_unsigned_extrinsic(
                    &self,
                    equivocation_proof: types::submit_report_equivocation_unsigned_extrinsic::EquivocationProof,
                    key_owner_proof: types::submit_report_equivocation_unsigned_extrinsic::KeyOwnerProof,
                ) -> ::subxt::runtime_api::Payload<
                    types::SubmitReportEquivocationUnsignedExtrinsic,
                    types::submit_report_equivocation_unsigned_extrinsic::output::Output,
                > {
                    ::subxt::runtime_api::Payload::new_static(
                        "GrandpaApi",
                        "submit_report_equivocation_unsigned_extrinsic",
                        types::SubmitReportEquivocationUnsignedExtrinsic { equivocation_proof, key_owner_proof },
                        [
                            112u8, 94u8, 150u8, 250u8, 132u8, 127u8, 185u8, 24u8, 113u8, 62u8, 28u8, 171u8, 83u8, 9u8,
                            41u8, 228u8, 92u8, 137u8, 29u8, 190u8, 214u8, 232u8, 100u8, 66u8, 100u8, 168u8, 149u8,
                            122u8, 93u8, 17u8, 236u8, 104u8,
                        ],
                    )
                }
                #[doc = " Generates a proof of key ownership for the given authority in the"]
                #[doc = " given set. An example usage of this module is coupled with the"]
                #[doc = " session historical module to prove that a given authority key is"]
                #[doc = " tied to a given staking identity during a specific session. Proofs"]
                #[doc = " of key ownership are necessary for submitting equivocation reports."]
                #[doc = " NOTE: even though the API takes a `set_id` as parameter the current"]
                #[doc = " implementations ignore this parameter and instead rely on this"]
                #[doc = " method being called at the correct block height, i.e. any point at"]
                #[doc = " which the given set id is live on-chain. Future implementations will"]
                #[doc = " instead use indexed data through an offchain worker, not requiring"]
                #[doc = " older states to be available."]
                pub fn generate_key_ownership_proof(
                    &self,
                    set_id: types::generate_key_ownership_proof::SetId,
                    authority_id: types::generate_key_ownership_proof::AuthorityId,
                ) -> ::subxt::runtime_api::Payload<
                    types::GenerateKeyOwnershipProof,
                    types::generate_key_ownership_proof::output::Output,
                > {
                    ::subxt::runtime_api::Payload::new_static(
                        "GrandpaApi",
                        "generate_key_ownership_proof",
                        types::GenerateKeyOwnershipProof { set_id, authority_id },
                        [
                            40u8, 126u8, 113u8, 27u8, 245u8, 45u8, 123u8, 138u8, 12u8, 3u8, 125u8, 186u8, 151u8, 53u8,
                            186u8, 93u8, 13u8, 150u8, 163u8, 176u8, 206u8, 89u8, 244u8, 127u8, 182u8, 85u8, 203u8,
                            41u8, 101u8, 183u8, 209u8, 179u8,
                        ],
                    )
                }
                #[doc = " Get current GRANDPA authority set id."]
                pub fn current_set_id(
                    &self,
                ) -> ::subxt::runtime_api::Payload<types::CurrentSetId, types::current_set_id::output::Output>
                {
                    ::subxt::runtime_api::Payload::new_static(
                        "GrandpaApi",
                        "current_set_id",
                        types::CurrentSetId {},
                        [
                            42u8, 230u8, 120u8, 211u8, 156u8, 245u8, 109u8, 86u8, 100u8, 146u8, 234u8, 205u8, 41u8,
                            183u8, 109u8, 42u8, 17u8, 33u8, 156u8, 25u8, 139u8, 84u8, 101u8, 75u8, 232u8, 198u8, 87u8,
                            136u8, 218u8, 233u8, 103u8, 156u8,
                        ],
                    )
                }
            }
            pub mod types {
                use super::runtime_types;
                pub mod grandpa_authorities {
                    use super::runtime_types;
                    pub mod output {
                        use super::runtime_types;
                        pub type Output =
                            ::std::vec::Vec<(runtime_types::sp_consensus_grandpa::app::Public, ::core::primitive::u64)>;
                    }
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct GrandpaAuthorities {}
                pub mod submit_report_equivocation_unsigned_extrinsic {
                    use super::runtime_types;
                    pub type EquivocationProof = runtime_types::sp_consensus_grandpa::EquivocationProof<
                        ::subxt::utils::H256,
                        ::core::primitive::u32,
                    >;
                    pub type KeyOwnerProof = runtime_types::sp_consensus_grandpa::OpaqueKeyOwnershipProof;
                    pub mod output {
                        use super::runtime_types;
                        pub type Output = ::core::option::Option<()>;
                    }
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct SubmitReportEquivocationUnsignedExtrinsic {
                    pub equivocation_proof: submit_report_equivocation_unsigned_extrinsic::EquivocationProof,
                    pub key_owner_proof: submit_report_equivocation_unsigned_extrinsic::KeyOwnerProof,
                }
                pub mod generate_key_ownership_proof {
                    use super::runtime_types;
                    pub type SetId = ::core::primitive::u64;
                    pub type AuthorityId = runtime_types::sp_consensus_grandpa::app::Public;
                    pub mod output {
                        use super::runtime_types;
                        pub type Output =
                            ::core::option::Option<runtime_types::sp_consensus_grandpa::OpaqueKeyOwnershipProof>;
                    }
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct GenerateKeyOwnershipProof {
                    pub set_id: generate_key_ownership_proof::SetId,
                    pub authority_id: generate_key_ownership_proof::AuthorityId,
                }
                pub mod current_set_id {
                    use super::runtime_types;
                    pub mod output {
                        use super::runtime_types;
                        pub type Output = ::core::primitive::u64;
                    }
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct CurrentSetId {}
            }
        }
        pub mod account_nonce_api {
            use super::root_mod;
            use super::runtime_types;
            #[doc = " The API to query account nonce."]
            pub struct AccountNonceApi;
            impl AccountNonceApi {
                #[doc = " Get current account nonce of given `AccountId`."]
                pub fn account_nonce(
                    &self,
                    account: types::account_nonce::Account,
                ) -> ::subxt::runtime_api::Payload<types::AccountNonce, types::account_nonce::output::Output>
                {
                    ::subxt::runtime_api::Payload::new_static(
                        "AccountNonceApi",
                        "account_nonce",
                        types::AccountNonce { account },
                        [
                            231u8, 82u8, 7u8, 227u8, 131u8, 2u8, 215u8, 252u8, 173u8, 82u8, 11u8, 103u8, 200u8, 25u8,
                            114u8, 116u8, 79u8, 229u8, 152u8, 150u8, 236u8, 37u8, 101u8, 26u8, 220u8, 146u8, 182u8,
                            101u8, 73u8, 55u8, 191u8, 171u8,
                        ],
                    )
                }
            }
            pub mod types {
                use super::runtime_types;
                pub mod account_nonce {
                    use super::runtime_types;
                    pub type Account = ::subxt::utils::AccountId32;
                    pub mod output {
                        use super::runtime_types;
                        pub type Output = ::core::primitive::u32;
                    }
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct AccountNonce {
                    pub account: account_nonce::Account,
                }
            }
        }
        pub mod starknet_runtime_api {
            use super::root_mod;
            use super::runtime_types;
            pub struct StarknetRuntimeApi;
            impl StarknetRuntimeApi {
                #[doc = " Returns the nonce associated with the given address in the given block"]
                pub fn nonce(
                    &self,
                    contract_address: types::nonce::ContractAddress,
                ) -> ::subxt::runtime_api::Payload<types::Nonce, types::nonce::output::Output> {
                    ::subxt::runtime_api::Payload::new_static(
                        "StarknetRuntimeApi",
                        "nonce",
                        types::Nonce { contract_address },
                        [
                            223u8, 78u8, 98u8, 162u8, 110u8, 80u8, 134u8, 64u8, 16u8, 48u8, 174u8, 206u8, 222u8, 135u8,
                            239u8, 38u8, 46u8, 199u8, 130u8, 229u8, 239u8, 236u8, 210u8, 57u8, 184u8, 219u8, 75u8, 1u8,
                            161u8, 76u8, 171u8, 90u8,
                        ],
                    )
                }
                #[doc = " Returns a storage slot value"]
                pub fn get_storage_at(
                    &self,
                    address: types::get_storage_at::Address,
                    key: types::get_storage_at::Key,
                ) -> ::subxt::runtime_api::Payload<types::GetStorageAt, types::get_storage_at::output::Output>
                {
                    ::subxt::runtime_api::Payload::new_static(
                        "StarknetRuntimeApi",
                        "get_storage_at",
                        types::GetStorageAt { address, key },
                        [
                            218u8, 70u8, 23u8, 117u8, 134u8, 149u8, 149u8, 52u8, 107u8, 184u8, 92u8, 60u8, 234u8, 81u8,
                            62u8, 254u8, 176u8, 3u8, 72u8, 252u8, 234u8, 226u8, 113u8, 3u8, 238u8, 139u8, 216u8, 182u8,
                            56u8, 200u8, 225u8, 44u8,
                        ],
                    )
                }
                #[doc = " Returns a `Call` response."]
                pub fn call(
                    &self,
                    address: types::call::Address,
                    function_selector: types::call::FunctionSelector,
                    calldata: types::call::Calldata,
                ) -> ::subxt::runtime_api::Payload<types::Call, types::call::output::Output> {
                    ::subxt::runtime_api::Payload::new_static(
                        "StarknetRuntimeApi",
                        "call",
                        types::Call { address, function_selector, calldata },
                        [
                            243u8, 171u8, 64u8, 174u8, 161u8, 137u8, 230u8, 19u8, 218u8, 58u8, 240u8, 15u8, 226u8,
                            41u8, 176u8, 172u8, 67u8, 234u8, 184u8, 21u8, 84u8, 198u8, 196u8, 55u8, 240u8, 128u8,
                            163u8, 75u8, 84u8, 235u8, 250u8, 249u8,
                        ],
                    )
                }
                #[doc = " Returns the contract class hash at the given address."]
                pub fn contract_class_hash_by_address(
                    &self,
                    address: types::contract_class_hash_by_address::Address,
                ) -> ::subxt::runtime_api::Payload<
                    types::ContractClassHashByAddress,
                    types::contract_class_hash_by_address::output::Output,
                > {
                    ::subxt::runtime_api::Payload::new_static(
                        "StarknetRuntimeApi",
                        "contract_class_hash_by_address",
                        types::ContractClassHashByAddress { address },
                        [
                            10u8, 25u8, 149u8, 78u8, 109u8, 81u8, 246u8, 45u8, 195u8, 195u8, 151u8, 125u8, 46u8, 227u8,
                            76u8, 43u8, 162u8, 103u8, 196u8, 137u8, 68u8, 10u8, 21u8, 70u8, 150u8, 244u8, 56u8, 61u8,
                            195u8, 204u8, 14u8, 20u8,
                        ],
                    )
                }
                #[doc = " Returns the contract class for the given class hash."]
                pub fn contract_class_by_class_hash(
                    &self,
                    class_hash: types::contract_class_by_class_hash::ClassHash,
                ) -> ::subxt::runtime_api::Payload<
                    types::ContractClassByClassHash,
                    types::contract_class_by_class_hash::output::Output,
                > {
                    ::subxt::runtime_api::Payload::new_static(
                        "StarknetRuntimeApi",
                        "contract_class_by_class_hash",
                        types::ContractClassByClassHash { class_hash },
                        [
                            101u8, 25u8, 72u8, 124u8, 184u8, 103u8, 59u8, 96u8, 180u8, 149u8, 213u8, 146u8, 67u8,
                            254u8, 43u8, 202u8, 71u8, 159u8, 249u8, 32u8, 59u8, 251u8, 35u8, 190u8, 128u8, 234u8, 61u8,
                            248u8, 181u8, 29u8, 126u8, 251u8,
                        ],
                    )
                }
                #[doc = " Returns the chain id."]
                pub fn chain_id(
                    &self,
                ) -> ::subxt::runtime_api::Payload<types::ChainId, types::chain_id::output::Output> {
                    ::subxt::runtime_api::Payload::new_static(
                        "StarknetRuntimeApi",
                        "chain_id",
                        types::ChainId {},
                        [
                            40u8, 205u8, 232u8, 235u8, 194u8, 248u8, 230u8, 70u8, 133u8, 162u8, 103u8, 163u8, 134u8,
                            9u8, 208u8, 149u8, 122u8, 242u8, 92u8, 98u8, 67u8, 7u8, 67u8, 223u8, 132u8, 110u8, 186u8,
                            220u8, 40u8, 179u8, 48u8, 91u8,
                        ],
                    )
                }
                #[doc = " Returns the Starknet OS Cairo program hash."]
                pub fn program_hash(
                    &self,
                ) -> ::subxt::runtime_api::Payload<types::ProgramHash, types::program_hash::output::Output>
                {
                    ::subxt::runtime_api::Payload::new_static(
                        "StarknetRuntimeApi",
                        "program_hash",
                        types::ProgramHash {},
                        [
                            172u8, 109u8, 196u8, 182u8, 116u8, 64u8, 49u8, 225u8, 138u8, 12u8, 135u8, 200u8, 217u8,
                            136u8, 64u8, 130u8, 0u8, 209u8, 221u8, 190u8, 9u8, 2u8, 143u8, 54u8, 84u8, 210u8, 195u8,
                            255u8, 110u8, 218u8, 216u8, 164u8,
                        ],
                    )
                }
                #[doc = " Returns the Starknet config hash."]
                pub fn config_hash(
                    &self,
                ) -> ::subxt::runtime_api::Payload<types::ConfigHash, types::config_hash::output::Output>
                {
                    ::subxt::runtime_api::Payload::new_static(
                        "StarknetRuntimeApi",
                        "config_hash",
                        types::ConfigHash {},
                        [
                            106u8, 73u8, 154u8, 190u8, 90u8, 106u8, 65u8, 70u8, 120u8, 248u8, 104u8, 75u8, 148u8,
                            184u8, 129u8, 205u8, 252u8, 31u8, 150u8, 31u8, 73u8, 164u8, 12u8, 251u8, 38u8, 116u8,
                            153u8, 79u8, 147u8, 193u8, 149u8, 0u8,
                        ],
                    )
                }
                #[doc = " Returns the fee token address."]
                pub fn fee_token_address(
                    &self,
                ) -> ::subxt::runtime_api::Payload<types::FeeTokenAddress, types::fee_token_address::output::Output>
                {
                    ::subxt::runtime_api::Payload::new_static(
                        "StarknetRuntimeApi",
                        "fee_token_address",
                        types::FeeTokenAddress {},
                        [
                            31u8, 130u8, 101u8, 106u8, 209u8, 212u8, 137u8, 207u8, 58u8, 18u8, 142u8, 195u8, 120u8,
                            208u8, 132u8, 228u8, 147u8, 115u8, 234u8, 25u8, 202u8, 254u8, 96u8, 39u8, 197u8, 144u8,
                            42u8, 92u8, 172u8, 82u8, 201u8, 204u8,
                        ],
                    )
                }
                #[doc = " Returns fee estimate"]
                pub fn estimate_fee(
                    &self,
                    transactions: types::estimate_fee::Transactions,
                ) -> ::subxt::runtime_api::Payload<types::EstimateFee, types::estimate_fee::output::Output>
                {
                    ::subxt::runtime_api::Payload::new_static(
                        "StarknetRuntimeApi",
                        "estimate_fee",
                        types::EstimateFee { transactions },
                        [
                            184u8, 182u8, 60u8, 242u8, 255u8, 251u8, 46u8, 30u8, 204u8, 104u8, 57u8, 131u8, 38u8, 50u8,
                            84u8, 156u8, 164u8, 26u8, 206u8, 149u8, 40u8, 170u8, 255u8, 7u8, 45u8, 93u8, 195u8, 64u8,
                            17u8, 8u8, 222u8, 14u8,
                        ],
                    )
                }
                #[doc = " Returns message fee estimate"]
                pub fn estimate_message_fee(
                    &self,
                    message: types::estimate_message_fee::Message,
                ) -> ::subxt::runtime_api::Payload<types::EstimateMessageFee, types::estimate_message_fee::output::Output>
                {
                    ::subxt::runtime_api::Payload::new_static(
                        "StarknetRuntimeApi",
                        "estimate_message_fee",
                        types::EstimateMessageFee { message },
                        [
                            109u8, 56u8, 101u8, 23u8, 94u8, 130u8, 118u8, 178u8, 136u8, 17u8, 122u8, 98u8, 86u8, 171u8,
                            19u8, 88u8, 130u8, 255u8, 208u8, 116u8, 99u8, 35u8, 201u8, 33u8, 226u8, 0u8, 66u8, 130u8,
                            74u8, 197u8, 253u8, 17u8,
                        ],
                    )
                }
                #[doc = " Simulates single L1 Message and returns its trace"]
                pub fn simulate_message(
                    &self,
                    message: types::simulate_message::Message,
                    simulation_flags: types::simulate_message::SimulationFlags,
                ) -> ::subxt::runtime_api::Payload<types::SimulateMessage, types::simulate_message::output::Output>
                {
                    ::subxt::runtime_api::Payload::new_static(
                        "StarknetRuntimeApi",
                        "simulate_message",
                        types::SimulateMessage { message, simulation_flags },
                        [
                            229u8, 57u8, 24u8, 201u8, 169u8, 96u8, 194u8, 117u8, 191u8, 75u8, 255u8, 98u8, 206u8,
                            115u8, 39u8, 119u8, 25u8, 230u8, 146u8, 3u8, 93u8, 78u8, 38u8, 166u8, 255u8, 72u8, 163u8,
                            33u8, 175u8, 71u8, 109u8, 116u8,
                        ],
                    )
                }
                #[doc = " Simulates transactions and returns their trace"]
                pub fn simulate_transactions(
                    &self,
                    transactions: types::simulate_transactions::Transactions,
                    simulation_flags: types::simulate_transactions::SimulationFlags,
                ) -> ::subxt::runtime_api::Payload<
                    types::SimulateTransactions,
                    types::simulate_transactions::output::Output,
                > {
                    ::subxt::runtime_api::Payload::new_static(
                        "StarknetRuntimeApi",
                        "simulate_transactions",
                        types::SimulateTransactions { transactions, simulation_flags },
                        [
                            188u8, 223u8, 156u8, 234u8, 56u8, 98u8, 85u8, 252u8, 78u8, 252u8, 164u8, 181u8, 16u8, 73u8,
                            49u8, 103u8, 174u8, 45u8, 168u8, 68u8, 172u8, 38u8, 216u8, 167u8, 239u8, 201u8, 18u8,
                            105u8, 242u8, 122u8, 227u8, 190u8,
                        ],
                    )
                }
                #[doc = " Filters extrinsic transactions to return only Starknet transactions"]
                #[doc = ""]
                #[doc = " To support runtime upgrades, the client must be unaware of the specific extrinsic"]
                #[doc = " details. To achieve this, the client uses an OpaqueExtrinsic type to represent and"]
                #[doc = " manipulate extrinsics. However, the client cannot decode and filter extrinsics due to"]
                #[doc = " this limitation. The solution is to offload decoding and filtering to the RuntimeApi in"]
                #[doc = " the runtime itself, accomplished through the extrinsic_filter method. This enables the"]
                #[doc = " client to operate seamlessly while abstracting the extrinsic complexity."]
                pub fn extrinsic_filter(
                    &self,
                    xts: types::extrinsic_filter::Xts,
                ) -> ::subxt::runtime_api::Payload<types::ExtrinsicFilter, types::extrinsic_filter::output::Output>
                {
                    ::subxt::runtime_api::Payload::new_static(
                        "StarknetRuntimeApi",
                        "extrinsic_filter",
                        types::ExtrinsicFilter { xts },
                        [
                            174u8, 71u8, 247u8, 222u8, 153u8, 41u8, 101u8, 40u8, 89u8, 39u8, 48u8, 240u8, 136u8, 23u8,
                            195u8, 201u8, 117u8, 235u8, 71u8, 30u8, 231u8, 151u8, 74u8, 224u8, 180u8, 205u8, 115u8,
                            110u8, 203u8, 95u8, 138u8, 157u8,
                        ],
                    )
                }
                #[doc = " Re-execute a block and return the TransactionExecutionInfos of every transaction in it, in the same order"]
                pub fn re_execute_transactions(
                    &self,
                    transactions: types::re_execute_transactions::Transactions,
                ) -> ::subxt::runtime_api::Payload<
                    types::ReExecuteTransactions,
                    types::re_execute_transactions::output::Output,
                > {
                    ::subxt::runtime_api::Payload::new_static(
                        "StarknetRuntimeApi",
                        "re_execute_transactions",
                        types::ReExecuteTransactions { transactions },
                        [
                            162u8, 224u8, 209u8, 166u8, 12u8, 75u8, 210u8, 149u8, 129u8, 76u8, 32u8, 42u8, 152u8, 97u8,
                            215u8, 135u8, 68u8, 92u8, 224u8, 141u8, 124u8, 175u8, 69u8, 116u8, 193u8, 49u8, 207u8,
                            216u8, 168u8, 235u8, 17u8, 252u8,
                        ],
                    )
                }
                pub fn get_index_and_tx_for_tx_hash(
                    &self,
                    xts: types::get_index_and_tx_for_tx_hash::Xts,
                    chain_id: types::get_index_and_tx_for_tx_hash::ChainId,
                    tx_hash: types::get_index_and_tx_for_tx_hash::TxHash,
                ) -> ::subxt::runtime_api::Payload<
                    types::GetIndexAndTxForTxHash,
                    types::get_index_and_tx_for_tx_hash::output::Output,
                > {
                    ::subxt::runtime_api::Payload::new_static(
                        "StarknetRuntimeApi",
                        "get_index_and_tx_for_tx_hash",
                        types::GetIndexAndTxForTxHash { xts, chain_id, tx_hash },
                        [
                            230u8, 69u8, 155u8, 160u8, 153u8, 166u8, 187u8, 237u8, 45u8, 101u8, 245u8, 24u8, 182u8,
                            192u8, 118u8, 68u8, 46u8, 103u8, 243u8, 155u8, 243u8, 252u8, 168u8, 34u8, 245u8, 242u8,
                            89u8, 4u8, 223u8, 150u8, 157u8, 155u8,
                        ],
                    )
                }
                pub fn get_events_for_tx_by_hash(
                    &self,
                    tx_hash: types::get_events_for_tx_by_hash::TxHash,
                ) -> ::subxt::runtime_api::Payload<
                    types::GetEventsForTxByHash,
                    types::get_events_for_tx_by_hash::output::Output,
                > {
                    ::subxt::runtime_api::Payload::new_static(
                        "StarknetRuntimeApi",
                        "get_events_for_tx_by_hash",
                        types::GetEventsForTxByHash { tx_hash },
                        [
                            9u8, 218u8, 79u8, 180u8, 233u8, 108u8, 107u8, 4u8, 15u8, 241u8, 8u8, 29u8, 187u8, 119u8,
                            92u8, 216u8, 95u8, 87u8, 115u8, 119u8, 234u8, 62u8, 227u8, 244u8, 20u8, 111u8, 17u8, 87u8,
                            125u8, 152u8, 80u8, 232u8,
                        ],
                    )
                }
                #[doc = " Return the outcome of the tx execution"]
                pub fn get_tx_execution_outcome(
                    &self,
                    tx_hash: types::get_tx_execution_outcome::TxHash,
                ) -> ::subxt::runtime_api::Payload<
                    types::GetTxExecutionOutcome,
                    types::get_tx_execution_outcome::output::Output,
                > {
                    ::subxt::runtime_api::Payload::new_static(
                        "StarknetRuntimeApi",
                        "get_tx_execution_outcome",
                        types::GetTxExecutionOutcome { tx_hash },
                        [
                            177u8, 94u8, 132u8, 75u8, 36u8, 225u8, 133u8, 68u8, 20u8, 144u8, 67u8, 79u8, 105u8, 190u8,
                            8u8, 234u8, 206u8, 112u8, 196u8, 133u8, 99u8, 175u8, 132u8, 113u8, 121u8, 7u8, 75u8, 9u8,
                            60u8, 96u8, 104u8, 64u8,
                        ],
                    )
                }
                #[doc = " Return the block context"]
                pub fn get_block_context(
                    &self,
                ) -> ::subxt::runtime_api::Payload<types::GetBlockContext, types::get_block_context::output::Output>
                {
                    ::subxt::runtime_api::Payload::new_static(
                        "StarknetRuntimeApi",
                        "get_block_context",
                        types::GetBlockContext {},
                        [
                            93u8, 141u8, 157u8, 168u8, 2u8, 15u8, 159u8, 49u8, 184u8, 176u8, 84u8, 196u8, 14u8, 245u8,
                            235u8, 121u8, 161u8, 89u8, 190u8, 195u8, 159u8, 128u8, 252u8, 231u8, 247u8, 142u8, 76u8,
                            182u8, 185u8, 130u8, 164u8, 115u8,
                        ],
                    )
                }
                #[doc = " Return is fee disabled in state"]
                pub fn is_transaction_fee_disabled(
                    &self,
                ) -> ::subxt::runtime_api::Payload<
                    types::IsTransactionFeeDisabled,
                    types::is_transaction_fee_disabled::output::Output,
                > {
                    ::subxt::runtime_api::Payload::new_static(
                        "StarknetRuntimeApi",
                        "is_transaction_fee_disabled",
                        types::IsTransactionFeeDisabled {},
                        [
                            248u8, 144u8, 121u8, 219u8, 115u8, 71u8, 41u8, 92u8, 164u8, 48u8, 110u8, 95u8, 31u8, 84u8,
                            38u8, 154u8, 47u8, 181u8, 115u8, 76u8, 138u8, 127u8, 209u8, 87u8, 70u8, 45u8, 237u8, 212u8,
                            250u8, 118u8, 164u8, 60u8,
                        ],
                    )
                }
                #[doc = " Return messages sent to L1 during tx execution"]
                pub fn get_tx_messages_to_l1(
                    &self,
                    tx_hash: types::get_tx_messages_to_l1::TxHash,
                ) -> ::subxt::runtime_api::Payload<types::GetTxMessagesToL1, types::get_tx_messages_to_l1::output::Output>
                {
                    ::subxt::runtime_api::Payload::new_static(
                        "StarknetRuntimeApi",
                        "get_tx_messages_to_l1",
                        types::GetTxMessagesToL1 { tx_hash },
                        [
                            117u8, 201u8, 150u8, 193u8, 49u8, 219u8, 210u8, 46u8, 10u8, 186u8, 195u8, 124u8, 137u8,
                            73u8, 127u8, 83u8, 120u8, 28u8, 61u8, 149u8, 195u8, 209u8, 193u8, 183u8, 63u8, 61u8, 104u8,
                            135u8, 236u8, 99u8, 104u8, 190u8,
                        ],
                    )
                }
                #[doc = " Check if L1 Message Nonce has not been used"]
                pub fn l1_nonce_unused(
                    &self,
                    nonce: types::l1_nonce_unused::Nonce,
                ) -> ::subxt::runtime_api::Payload<types::L1NonceUnused, types::l1_nonce_unused::output::Output>
                {
                    ::subxt::runtime_api::Payload::new_static(
                        "StarknetRuntimeApi",
                        "l1_nonce_unused",
                        types::L1NonceUnused { nonce },
                        [
                            210u8, 236u8, 76u8, 166u8, 82u8, 158u8, 90u8, 74u8, 152u8, 155u8, 167u8, 49u8, 230u8, 42u8,
                            155u8, 111u8, 168u8, 113u8, 135u8, 163u8, 139u8, 93u8, 179u8, 212u8, 169u8, 175u8, 53u8,
                            65u8, 142u8, 138u8, 146u8, 232u8,
                        ],
                    )
                }
            }
            pub mod types {
                use super::runtime_types;
                pub mod nonce {
                    use super::runtime_types;
                    pub type ContractAddress = runtime_types::starknet_api::api_core::ContractAddress;
                    pub mod output {
                        use super::runtime_types;
                        pub type Output = runtime_types::starknet_api::api_core::Nonce;
                    }
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct Nonce {
                    pub contract_address: nonce::ContractAddress,
                }
                pub mod get_storage_at {
                    use super::runtime_types;
                    pub type Address = runtime_types::starknet_api::api_core::ContractAddress;
                    pub type Key = runtime_types::starknet_api::state::StorageKey;
                    pub mod output {
                        use super::runtime_types;
                        pub type Output = ::core::result::Result<
                            runtime_types::starknet_api::hash::StarkFelt,
                            runtime_types::sp_runtime::DispatchError,
                        >;
                    }
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct GetStorageAt {
                    pub address: get_storage_at::Address,
                    pub key: get_storage_at::Key,
                }
                pub mod call {
                    use super::runtime_types;
                    pub type Address = runtime_types::starknet_api::api_core::ContractAddress;
                    pub type FunctionSelector = runtime_types::starknet_api::api_core::EntryPointSelector;
                    pub type Calldata = runtime_types::starknet_api::transaction::Calldata;
                    pub mod output {
                        use super::runtime_types;
                        pub type Output = ::core::result::Result<
                            ::std::vec::Vec<runtime_types::mp_felt::Felt252Wrapper>,
                            runtime_types::sp_runtime::DispatchError,
                        >;
                    }
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct Call {
                    pub address: call::Address,
                    pub function_selector: call::FunctionSelector,
                    pub calldata: call::Calldata,
                }
                pub mod contract_class_hash_by_address {
                    use super::runtime_types;
                    pub type Address = runtime_types::starknet_api::api_core::ContractAddress;
                    pub mod output {
                        use super::runtime_types;
                        pub type Output = runtime_types::starknet_api::api_core::ClassHash;
                    }
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct ContractClassHashByAddress {
                    pub address: contract_class_hash_by_address::Address,
                }
                pub mod contract_class_by_class_hash {
                    use super::runtime_types;
                    pub type ClassHash = runtime_types::starknet_api::api_core::ClassHash;
                    pub mod output {
                        use super::runtime_types;
                        pub type Output =
                            ::core::option::Option<runtime_types::blockifier::execution::contract_class::ContractClass>;
                    }
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct ContractClassByClassHash {
                    pub class_hash: contract_class_by_class_hash::ClassHash,
                }
                pub mod chain_id {
                    use super::runtime_types;
                    pub mod output {
                        use super::runtime_types;
                        pub type Output = runtime_types::mp_felt::Felt252Wrapper;
                    }
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct ChainId {}
                pub mod program_hash {
                    use super::runtime_types;
                    pub mod output {
                        use super::runtime_types;
                        pub type Output = runtime_types::mp_felt::Felt252Wrapper;
                    }
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct ProgramHash {}
                pub mod config_hash {
                    use super::runtime_types;
                    pub mod output {
                        use super::runtime_types;
                        pub type Output = runtime_types::starknet_api::hash::StarkFelt;
                    }
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct ConfigHash {}
                pub mod fee_token_address {
                    use super::runtime_types;
                    pub mod output {
                        use super::runtime_types;
                        pub type Output = runtime_types::starknet_api::api_core::ContractAddress;
                    }
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct FeeTokenAddress {}
                pub mod estimate_fee {
                    use super::runtime_types;
                    pub type Transactions = ::std::vec::Vec<runtime_types::mp_transactions::UserTransaction>;
                    pub mod output {
                        use super::runtime_types;
                        pub type Output = ::core::result::Result<
                            ::std::vec::Vec<(::core::primitive::u64, ::core::primitive::u64)>,
                            runtime_types::sp_runtime::DispatchError,
                        >;
                    }
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct EstimateFee {
                    pub transactions: estimate_fee::Transactions,
                }
                pub mod estimate_message_fee {
                    use super::runtime_types;
                    pub type Message = runtime_types::mp_transactions::HandleL1MessageTransaction;
                    pub mod output {
                        use super::runtime_types;
                        pub type Output = ::core::result::Result<
                            (::core::primitive::u128, ::core::primitive::u64, ::core::primitive::u64),
                            runtime_types::sp_runtime::DispatchError,
                        >;
                    }
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct EstimateMessageFee {
                    pub message: estimate_message_fee::Message,
                }
                pub mod simulate_message {
                    use super::runtime_types;
                    pub type Message = runtime_types::mp_transactions::HandleL1MessageTransaction;
                    pub type SimulationFlags = runtime_types::mp_simulations::SimulationFlags;
                    pub mod output {
                        use super::runtime_types;
                        pub type Output = ::core::result::Result<
                            ::core::result::Result<
                                runtime_types::blockifier::transaction::objects::TransactionExecutionInfo,
                                runtime_types::mp_simulations::PlaceHolderErrorTypeForFailedStarknetExecution,
                            >,
                            runtime_types::sp_runtime::DispatchError,
                        >;
                    }
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct SimulateMessage {
                    pub message: simulate_message::Message,
                    pub simulation_flags: simulate_message::SimulationFlags,
                }
                pub mod simulate_transactions {
                    use super::runtime_types;
                    pub type Transactions = ::std::vec::Vec<runtime_types::mp_transactions::UserTransaction>;
                    pub type SimulationFlags = runtime_types::mp_simulations::SimulationFlags;
                    pub mod output {
                        use super::runtime_types;
                        pub type Output = ::core::result::Result<
                            ::std::vec::Vec<(
                                runtime_types::blockifier::state::cached_state::CommitmentStateDiff,
                                ::core::result::Result<
                                    runtime_types::blockifier::transaction::objects::TransactionExecutionInfo,
                                    runtime_types::mp_simulations::PlaceHolderErrorTypeForFailedStarknetExecution,
                                >,
                            )>,
                            runtime_types::sp_runtime::DispatchError,
                        >;
                    }
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct SimulateTransactions {
                    pub transactions: simulate_transactions::Transactions,
                    pub simulation_flags: simulate_transactions::SimulationFlags,
                }
                pub mod extrinsic_filter {
                    use super::runtime_types;
                    pub type Xts = ::std::vec::Vec<
                        ::subxt::utils::UncheckedExtrinsic<
                            ::subxt::utils::MultiAddress<::subxt::utils::AccountId32, ()>,
                            runtime_types::madara_runtime::RuntimeCall,
                            runtime_types::sp_runtime::MultiSignature,
                            (
                                runtime_types::frame_system::extensions::check_non_zero_sender::CheckNonZeroSender,
                                runtime_types::frame_system::extensions::check_spec_version::CheckSpecVersion,
                                runtime_types::frame_system::extensions::check_tx_version::CheckTxVersion,
                                runtime_types::frame_system::extensions::check_genesis::CheckGenesis,
                                runtime_types::frame_system::extensions::check_mortality::CheckMortality,
                                runtime_types::frame_system::extensions::check_nonce::CheckNonce,
                                runtime_types::frame_system::extensions::check_weight::CheckWeight,
                            ),
                        >,
                    >;
                    pub mod output {
                        use super::runtime_types;
                        pub type Output = ::std::vec::Vec<runtime_types::mp_transactions::Transaction>;
                    }
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct ExtrinsicFilter {
                    pub xts: extrinsic_filter::Xts,
                }
                pub mod re_execute_transactions {
                    use super::runtime_types;
                    pub type Transactions = ::std::vec::Vec<runtime_types::mp_transactions::UserOrL1HandlerTransaction>;
                    pub mod output {
                        use super::runtime_types;
                        pub type Output = ::core::result::Result<
                            ::core::result::Result<
                                ::std::vec::Vec<(
                                    runtime_types::blockifier::transaction::objects::TransactionExecutionInfo,
                                    runtime_types::blockifier::state::cached_state::CommitmentStateDiff,
                                )>,
                                runtime_types::mp_simulations::PlaceHolderErrorTypeForFailedStarknetExecution,
                            >,
                            runtime_types::sp_runtime::DispatchError,
                        >;
                    }
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct ReExecuteTransactions {
                    pub transactions: re_execute_transactions::Transactions,
                }
                pub mod get_index_and_tx_for_tx_hash {
                    use super::runtime_types;
                    pub type Xts = ::std::vec::Vec<
                        ::subxt::utils::UncheckedExtrinsic<
                            ::subxt::utils::MultiAddress<::subxt::utils::AccountId32, ()>,
                            runtime_types::madara_runtime::RuntimeCall,
                            runtime_types::sp_runtime::MultiSignature,
                            (
                                runtime_types::frame_system::extensions::check_non_zero_sender::CheckNonZeroSender,
                                runtime_types::frame_system::extensions::check_spec_version::CheckSpecVersion,
                                runtime_types::frame_system::extensions::check_tx_version::CheckTxVersion,
                                runtime_types::frame_system::extensions::check_genesis::CheckGenesis,
                                runtime_types::frame_system::extensions::check_mortality::CheckMortality,
                                runtime_types::frame_system::extensions::check_nonce::CheckNonce,
                                runtime_types::frame_system::extensions::check_weight::CheckWeight,
                            ),
                        >,
                    >;
                    pub type ChainId = runtime_types::mp_felt::Felt252Wrapper;
                    pub type TxHash = runtime_types::mp_felt::Felt252Wrapper;
                    pub mod output {
                        use super::runtime_types;
                        pub type Output = ::core::option::Option<(
                            ::core::primitive::u32,
                            runtime_types::mp_transactions::Transaction,
                        )>;
                    }
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct GetIndexAndTxForTxHash {
                    pub xts: get_index_and_tx_for_tx_hash::Xts,
                    pub chain_id: get_index_and_tx_for_tx_hash::ChainId,
                    pub tx_hash: get_index_and_tx_for_tx_hash::TxHash,
                }
                pub mod get_events_for_tx_by_hash {
                    use super::runtime_types;
                    pub type TxHash = runtime_types::starknet_api::transaction::TransactionHash;
                    pub mod output {
                        use super::runtime_types;
                        pub type Output = ::std::vec::Vec<runtime_types::starknet_api::transaction::Event>;
                    }
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct GetEventsForTxByHash {
                    pub tx_hash: get_events_for_tx_by_hash::TxHash,
                }
                pub mod get_tx_execution_outcome {
                    use super::runtime_types;
                    pub type TxHash = runtime_types::starknet_api::transaction::TransactionHash;
                    pub mod output {
                        use super::runtime_types;
                        pub type Output = ::core::option::Option<::std::vec::Vec<::core::primitive::u8>>;
                    }
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct GetTxExecutionOutcome {
                    pub tx_hash: get_tx_execution_outcome::TxHash,
                }
                pub mod get_block_context {
                    use super::runtime_types;
                    pub mod output {
                        use super::runtime_types;
                        pub type Output = runtime_types::pallet_starknet_runtime_api::BlockContext;
                    }
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct GetBlockContext {}
                pub mod is_transaction_fee_disabled {
                    use super::runtime_types;
                    pub mod output {
                        use super::runtime_types;
                        pub type Output = ::core::primitive::bool;
                    }
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct IsTransactionFeeDisabled {}
                pub mod get_tx_messages_to_l1 {
                    use super::runtime_types;
                    pub type TxHash = runtime_types::starknet_api::transaction::TransactionHash;
                    pub mod output {
                        use super::runtime_types;
                        pub type Output = ::std::vec::Vec<runtime_types::starknet_api::transaction::MessageToL1>;
                    }
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct GetTxMessagesToL1 {
                    pub tx_hash: get_tx_messages_to_l1::TxHash,
                }
                pub mod l1_nonce_unused {
                    use super::runtime_types;
                    pub type Nonce = runtime_types::starknet_api::api_core::Nonce;
                    pub mod output {
                        use super::runtime_types;
                        pub type Output = ::core::primitive::bool;
                    }
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct L1NonceUnused {
                    pub nonce: l1_nonce_unused::Nonce,
                }
            }
        }
        pub mod convert_transaction_runtime_api {
            use super::root_mod;
            use super::runtime_types;
            pub struct ConvertTransactionRuntimeApi;
            impl ConvertTransactionRuntimeApi {
                #[doc = " Converts the transaction to an UncheckedExtrinsic for submission to the pool."]
                pub fn convert_transaction(
                    &self,
                    transaction: types::convert_transaction::Transaction,
                ) -> ::subxt::runtime_api::Payload<types::ConvertTransaction, types::convert_transaction::output::Output>
                {
                    ::subxt::runtime_api::Payload::new_static(
                        "ConvertTransactionRuntimeApi",
                        "convert_transaction",
                        types::ConvertTransaction { transaction },
                        [
                            2u8, 28u8, 195u8, 173u8, 73u8, 16u8, 65u8, 48u8, 228u8, 175u8, 103u8, 175u8, 208u8, 146u8,
                            110u8, 70u8, 70u8, 124u8, 194u8, 14u8, 172u8, 153u8, 223u8, 148u8, 224u8, 104u8, 185u8,
                            128u8, 129u8, 12u8, 21u8, 136u8,
                        ],
                    )
                }
                #[doc = " Converts the L1 Message transaction to an UncheckedExtrinsic for submission to the pool."]
                pub fn convert_l1_transaction(
                    &self,
                    transaction: types::convert_l1_transaction::Transaction,
                    fee: types::convert_l1_transaction::Fee,
                ) -> ::subxt::runtime_api::Payload<
                    types::ConvertL1Transaction,
                    types::convert_l1_transaction::output::Output,
                > {
                    ::subxt::runtime_api::Payload::new_static(
                        "ConvertTransactionRuntimeApi",
                        "convert_l1_transaction",
                        types::ConvertL1Transaction { transaction, fee },
                        [
                            144u8, 54u8, 178u8, 219u8, 51u8, 230u8, 156u8, 233u8, 63u8, 216u8, 248u8, 105u8, 227u8,
                            232u8, 201u8, 53u8, 243u8, 182u8, 84u8, 171u8, 249u8, 140u8, 79u8, 70u8, 95u8, 25u8, 196u8,
                            10u8, 127u8, 75u8, 83u8, 65u8,
                        ],
                    )
                }
                #[doc = " Converts the DispatchError to an understandable error for the client"]
                pub fn convert_error(
                    &self,
                    error: types::convert_error::Error,
                ) -> ::subxt::runtime_api::Payload<types::ConvertError, types::convert_error::output::Output>
                {
                    ::subxt::runtime_api::Payload::new_static(
                        "ConvertTransactionRuntimeApi",
                        "convert_error",
                        types::ConvertError { error },
                        [
                            99u8, 109u8, 225u8, 103u8, 141u8, 72u8, 147u8, 132u8, 251u8, 176u8, 127u8, 246u8, 28u8,
                            171u8, 244u8, 204u8, 159u8, 42u8, 215u8, 195u8, 88u8, 246u8, 173u8, 193u8, 46u8, 170u8,
                            188u8, 147u8, 113u8, 158u8, 243u8, 203u8,
                        ],
                    )
                }
            }
            pub mod types {
                use super::runtime_types;
                pub mod convert_transaction {
                    use super::runtime_types;
                    pub type Transaction = runtime_types::mp_transactions::UserTransaction;
                    pub mod output {
                        use super::runtime_types;
                        pub type Output = ::subxt::utils::UncheckedExtrinsic<
                            ::subxt::utils::MultiAddress<::subxt::utils::AccountId32, ()>,
                            runtime_types::madara_runtime::RuntimeCall,
                            runtime_types::sp_runtime::MultiSignature,
                            (
                                runtime_types::frame_system::extensions::check_non_zero_sender::CheckNonZeroSender,
                                runtime_types::frame_system::extensions::check_spec_version::CheckSpecVersion,
                                runtime_types::frame_system::extensions::check_tx_version::CheckTxVersion,
                                runtime_types::frame_system::extensions::check_genesis::CheckGenesis,
                                runtime_types::frame_system::extensions::check_mortality::CheckMortality,
                                runtime_types::frame_system::extensions::check_nonce::CheckNonce,
                                runtime_types::frame_system::extensions::check_weight::CheckWeight,
                            ),
                        >;
                    }
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct ConvertTransaction {
                    pub transaction: convert_transaction::Transaction,
                }
                pub mod convert_l1_transaction {
                    use super::runtime_types;
                    pub type Transaction = runtime_types::mp_transactions::HandleL1MessageTransaction;
                    pub type Fee = runtime_types::starknet_api::transaction::Fee;
                    pub mod output {
                        use super::runtime_types;
                        pub type Output = ::subxt::utils::UncheckedExtrinsic<
                            ::subxt::utils::MultiAddress<::subxt::utils::AccountId32, ()>,
                            runtime_types::madara_runtime::RuntimeCall,
                            runtime_types::sp_runtime::MultiSignature,
                            (
                                runtime_types::frame_system::extensions::check_non_zero_sender::CheckNonZeroSender,
                                runtime_types::frame_system::extensions::check_spec_version::CheckSpecVersion,
                                runtime_types::frame_system::extensions::check_tx_version::CheckTxVersion,
                                runtime_types::frame_system::extensions::check_genesis::CheckGenesis,
                                runtime_types::frame_system::extensions::check_mortality::CheckMortality,
                                runtime_types::frame_system::extensions::check_nonce::CheckNonce,
                                runtime_types::frame_system::extensions::check_weight::CheckWeight,
                            ),
                        >;
                    }
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct ConvertL1Transaction {
                    pub transaction: convert_l1_transaction::Transaction,
                    pub fee: convert_l1_transaction::Fee,
                }
                pub mod convert_error {
                    use super::runtime_types;
                    pub type Error = runtime_types::sp_runtime::DispatchError;
                    pub mod output {
                        use super::runtime_types;
                        pub type Output = runtime_types::pallet_starknet_runtime_api::StarknetTransactionExecutionError;
                    }
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct ConvertError {
                    pub error: convert_error::Error,
                }
            }
        }
    }
    pub fn custom() -> CustomValuesApi {
        CustomValuesApi
    }
    pub struct CustomValuesApi;
    impl CustomValuesApi {}
    pub struct ConstantsApi;
    impl ConstantsApi {
        pub fn system(&self) -> system::constants::ConstantsApi {
            system::constants::ConstantsApi
        }
        pub fn timestamp(&self) -> timestamp::constants::ConstantsApi {
            timestamp::constants::ConstantsApi
        }
        pub fn grandpa(&self) -> grandpa::constants::ConstantsApi {
            grandpa::constants::ConstantsApi
        }
        pub fn starknet(&self) -> starknet::constants::ConstantsApi {
            starknet::constants::ConstantsApi
        }
        pub fn autonomous(&self) -> autonomous::constants::ConstantsApi {
            autonomous::constants::ConstantsApi
        }
    }
    pub struct StorageApi;
    impl StorageApi {
        pub fn system(&self) -> system::storage::StorageApi {
            system::storage::StorageApi
        }
        pub fn timestamp(&self) -> timestamp::storage::StorageApi {
            timestamp::storage::StorageApi
        }
        pub fn aura(&self) -> aura::storage::StorageApi {
            aura::storage::StorageApi
        }
        pub fn grandpa(&self) -> grandpa::storage::StorageApi {
            grandpa::storage::StorageApi
        }
        pub fn starknet(&self) -> starknet::storage::StorageApi {
            starknet::storage::StorageApi
        }
        pub fn autonomous(&self) -> autonomous::storage::StorageApi {
            autonomous::storage::StorageApi
        }
    }
    pub struct TransactionApi;
    impl TransactionApi {
        pub fn system(&self) -> system::calls::TransactionApi {
            system::calls::TransactionApi
        }
        pub fn timestamp(&self) -> timestamp::calls::TransactionApi {
            timestamp::calls::TransactionApi
        }
        pub fn grandpa(&self) -> grandpa::calls::TransactionApi {
            grandpa::calls::TransactionApi
        }
        pub fn starknet(&self) -> starknet::calls::TransactionApi {
            starknet::calls::TransactionApi
        }
        pub fn autonomous(&self) -> autonomous::calls::TransactionApi {
            autonomous::calls::TransactionApi
        }
    }
    #[doc = r" check whether the metadata provided is aligned with this statically generated code."]
    pub fn is_codegen_valid_for(metadata: &::subxt::Metadata) -> bool {
        let runtime_metadata_hash =
            metadata.hasher().only_these_pallets(&PALLETS).only_these_runtime_apis(&RUNTIME_APIS).hash();
        runtime_metadata_hash
            == [
                117u8, 185u8, 174u8, 237u8, 196u8, 139u8, 66u8, 59u8, 25u8, 86u8, 75u8, 39u8, 46u8, 226u8, 30u8, 205u8,
                54u8, 201u8, 140u8, 156u8, 175u8, 241u8, 134u8, 233u8, 233u8, 215u8, 159u8, 145u8, 119u8, 176u8, 38u8,
                59u8,
            ]
    }
    pub mod system {
        use super::root_mod;
        use super::runtime_types;
        #[doc = "Error for the System pallet"]
        pub type Error = runtime_types::frame_system::pallet::Error;
        #[doc = "Contains a variant per dispatchable extrinsic that this pallet has."]
        pub type Call = runtime_types::frame_system::pallet::Call;
        pub mod calls {
            use super::root_mod;
            use super::runtime_types;
            type DispatchError = runtime_types::sp_runtime::DispatchError;
            pub mod types {
                use super::runtime_types;
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                #[doc = "See [`Pallet::remark`]."]
                pub struct Remark {
                    pub remark: remark::Remark,
                }
                pub mod remark {
                    use super::runtime_types;
                    pub type Remark = ::std::vec::Vec<::core::primitive::u8>;
                }
                impl ::subxt::blocks::StaticExtrinsic for Remark {
                    const PALLET: &'static str = "System";
                    const CALL: &'static str = "remark";
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                #[doc = "See [`Pallet::set_heap_pages`]."]
                pub struct SetHeapPages {
                    pub pages: set_heap_pages::Pages,
                }
                pub mod set_heap_pages {
                    use super::runtime_types;
                    pub type Pages = ::core::primitive::u64;
                }
                impl ::subxt::blocks::StaticExtrinsic for SetHeapPages {
                    const PALLET: &'static str = "System";
                    const CALL: &'static str = "set_heap_pages";
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                #[doc = "See [`Pallet::set_code`]."]
                pub struct SetCode {
                    pub code: set_code::Code,
                }
                pub mod set_code {
                    use super::runtime_types;
                    pub type Code = ::std::vec::Vec<::core::primitive::u8>;
                }
                impl ::subxt::blocks::StaticExtrinsic for SetCode {
                    const PALLET: &'static str = "System";
                    const CALL: &'static str = "set_code";
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                #[doc = "See [`Pallet::set_code_without_checks`]."]
                pub struct SetCodeWithoutChecks {
                    pub code: set_code_without_checks::Code,
                }
                pub mod set_code_without_checks {
                    use super::runtime_types;
                    pub type Code = ::std::vec::Vec<::core::primitive::u8>;
                }
                impl ::subxt::blocks::StaticExtrinsic for SetCodeWithoutChecks {
                    const PALLET: &'static str = "System";
                    const CALL: &'static str = "set_code_without_checks";
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                #[doc = "See [`Pallet::set_storage`]."]
                pub struct SetStorage {
                    pub items: set_storage::Items,
                }
                pub mod set_storage {
                    use super::runtime_types;
                    pub type Items = ::std::vec::Vec<(
                        ::std::vec::Vec<::core::primitive::u8>,
                        ::std::vec::Vec<::core::primitive::u8>,
                    )>;
                }
                impl ::subxt::blocks::StaticExtrinsic for SetStorage {
                    const PALLET: &'static str = "System";
                    const CALL: &'static str = "set_storage";
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                #[doc = "See [`Pallet::kill_storage`]."]
                pub struct KillStorage {
                    pub keys: kill_storage::Keys,
                }
                pub mod kill_storage {
                    use super::runtime_types;
                    pub type Keys = ::std::vec::Vec<::std::vec::Vec<::core::primitive::u8>>;
                }
                impl ::subxt::blocks::StaticExtrinsic for KillStorage {
                    const PALLET: &'static str = "System";
                    const CALL: &'static str = "kill_storage";
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                #[doc = "See [`Pallet::kill_prefix`]."]
                pub struct KillPrefix {
                    pub prefix: kill_prefix::Prefix,
                    pub subkeys: kill_prefix::Subkeys,
                }
                pub mod kill_prefix {
                    use super::runtime_types;
                    pub type Prefix = ::std::vec::Vec<::core::primitive::u8>;
                    pub type Subkeys = ::core::primitive::u32;
                }
                impl ::subxt::blocks::StaticExtrinsic for KillPrefix {
                    const PALLET: &'static str = "System";
                    const CALL: &'static str = "kill_prefix";
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                #[doc = "See [`Pallet::remark_with_event`]."]
                pub struct RemarkWithEvent {
                    pub remark: remark_with_event::Remark,
                }
                pub mod remark_with_event {
                    use super::runtime_types;
                    pub type Remark = ::std::vec::Vec<::core::primitive::u8>;
                }
                impl ::subxt::blocks::StaticExtrinsic for RemarkWithEvent {
                    const PALLET: &'static str = "System";
                    const CALL: &'static str = "remark_with_event";
                }
            }
            pub struct TransactionApi;
            impl TransactionApi {
                #[doc = "See [`Pallet::remark`]."]
                pub fn remark(&self, remark: types::remark::Remark) -> ::subxt::tx::Payload<types::Remark> {
                    ::subxt::tx::Payload::new_static(
                        "System",
                        "remark",
                        types::Remark { remark },
                        [
                            43u8, 126u8, 180u8, 174u8, 141u8, 48u8, 52u8, 125u8, 166u8, 212u8, 216u8, 98u8, 100u8,
                            24u8, 132u8, 71u8, 101u8, 64u8, 246u8, 169u8, 33u8, 250u8, 147u8, 208u8, 2u8, 40u8, 129u8,
                            209u8, 232u8, 207u8, 207u8, 13u8,
                        ],
                    )
                }
                #[doc = "See [`Pallet::set_heap_pages`]."]
                pub fn set_heap_pages(
                    &self,
                    pages: types::set_heap_pages::Pages,
                ) -> ::subxt::tx::Payload<types::SetHeapPages> {
                    ::subxt::tx::Payload::new_static(
                        "System",
                        "set_heap_pages",
                        types::SetHeapPages { pages },
                        [
                            188u8, 191u8, 99u8, 216u8, 219u8, 109u8, 141u8, 50u8, 78u8, 235u8, 215u8, 242u8, 195u8,
                            24u8, 111u8, 76u8, 229u8, 64u8, 99u8, 225u8, 134u8, 121u8, 81u8, 209u8, 127u8, 223u8, 98u8,
                            215u8, 150u8, 70u8, 57u8, 147u8,
                        ],
                    )
                }
                #[doc = "See [`Pallet::set_code`]."]
                pub fn set_code(&self, code: types::set_code::Code) -> ::subxt::tx::Payload<types::SetCode> {
                    ::subxt::tx::Payload::new_static(
                        "System",
                        "set_code",
                        types::SetCode { code },
                        [
                            233u8, 248u8, 88u8, 245u8, 28u8, 65u8, 25u8, 169u8, 35u8, 237u8, 19u8, 203u8, 136u8, 160u8,
                            18u8, 3u8, 20u8, 197u8, 81u8, 169u8, 244u8, 188u8, 27u8, 147u8, 147u8, 236u8, 65u8, 25u8,
                            3u8, 143u8, 182u8, 22u8,
                        ],
                    )
                }
                #[doc = "See [`Pallet::set_code_without_checks`]."]
                pub fn set_code_without_checks(
                    &self,
                    code: types::set_code_without_checks::Code,
                ) -> ::subxt::tx::Payload<types::SetCodeWithoutChecks> {
                    ::subxt::tx::Payload::new_static(
                        "System",
                        "set_code_without_checks",
                        types::SetCodeWithoutChecks { code },
                        [
                            82u8, 212u8, 157u8, 44u8, 70u8, 0u8, 143u8, 15u8, 109u8, 109u8, 107u8, 157u8, 141u8, 42u8,
                            169u8, 11u8, 15u8, 186u8, 252u8, 138u8, 10u8, 147u8, 15u8, 178u8, 247u8, 229u8, 213u8,
                            98u8, 207u8, 231u8, 119u8, 115u8,
                        ],
                    )
                }
                #[doc = "See [`Pallet::set_storage`]."]
                pub fn set_storage(&self, items: types::set_storage::Items) -> ::subxt::tx::Payload<types::SetStorage> {
                    ::subxt::tx::Payload::new_static(
                        "System",
                        "set_storage",
                        types::SetStorage { items },
                        [
                            141u8, 216u8, 52u8, 222u8, 223u8, 136u8, 123u8, 181u8, 19u8, 75u8, 163u8, 102u8, 229u8,
                            189u8, 158u8, 142u8, 95u8, 235u8, 240u8, 49u8, 150u8, 76u8, 78u8, 137u8, 126u8, 88u8,
                            183u8, 88u8, 231u8, 146u8, 234u8, 43u8,
                        ],
                    )
                }
                #[doc = "See [`Pallet::kill_storage`]."]
                pub fn kill_storage(
                    &self,
                    keys: types::kill_storage::Keys,
                ) -> ::subxt::tx::Payload<types::KillStorage> {
                    ::subxt::tx::Payload::new_static(
                        "System",
                        "kill_storage",
                        types::KillStorage { keys },
                        [
                            73u8, 63u8, 196u8, 36u8, 144u8, 114u8, 34u8, 213u8, 108u8, 93u8, 209u8, 234u8, 153u8,
                            185u8, 33u8, 91u8, 187u8, 195u8, 223u8, 130u8, 58u8, 156u8, 63u8, 47u8, 228u8, 249u8,
                            216u8, 139u8, 143u8, 177u8, 41u8, 35u8,
                        ],
                    )
                }
                #[doc = "See [`Pallet::kill_prefix`]."]
                pub fn kill_prefix(
                    &self,
                    prefix: types::kill_prefix::Prefix,
                    subkeys: types::kill_prefix::Subkeys,
                ) -> ::subxt::tx::Payload<types::KillPrefix> {
                    ::subxt::tx::Payload::new_static(
                        "System",
                        "kill_prefix",
                        types::KillPrefix { prefix, subkeys },
                        [
                            184u8, 57u8, 139u8, 24u8, 208u8, 87u8, 108u8, 215u8, 198u8, 189u8, 175u8, 242u8, 167u8,
                            215u8, 97u8, 63u8, 110u8, 166u8, 238u8, 98u8, 67u8, 236u8, 111u8, 110u8, 234u8, 81u8,
                            102u8, 5u8, 182u8, 5u8, 214u8, 85u8,
                        ],
                    )
                }
                #[doc = "See [`Pallet::remark_with_event`]."]
                pub fn remark_with_event(
                    &self,
                    remark: types::remark_with_event::Remark,
                ) -> ::subxt::tx::Payload<types::RemarkWithEvent> {
                    ::subxt::tx::Payload::new_static(
                        "System",
                        "remark_with_event",
                        types::RemarkWithEvent { remark },
                        [
                            120u8, 120u8, 153u8, 92u8, 184u8, 85u8, 34u8, 2u8, 174u8, 206u8, 105u8, 228u8, 233u8,
                            130u8, 80u8, 246u8, 228u8, 59u8, 234u8, 240u8, 4u8, 49u8, 147u8, 170u8, 115u8, 91u8, 149u8,
                            200u8, 228u8, 181u8, 8u8, 154u8,
                        ],
                    )
                }
            }
        }
        #[doc = "Event for the System pallet."]
        pub type Event = runtime_types::frame_system::pallet::Event;
        pub mod events {
            use super::runtime_types;
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            #[doc = "An extrinsic completed successfully."]
            pub struct ExtrinsicSuccess {
                pub dispatch_info: extrinsic_success::DispatchInfo,
            }
            pub mod extrinsic_success {
                use super::runtime_types;
                pub type DispatchInfo = runtime_types::frame_support::dispatch::DispatchInfo;
            }
            impl ::subxt::events::StaticEvent for ExtrinsicSuccess {
                const PALLET: &'static str = "System";
                const EVENT: &'static str = "ExtrinsicSuccess";
            }
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            #[doc = "An extrinsic failed."]
            pub struct ExtrinsicFailed {
                pub dispatch_error: extrinsic_failed::DispatchError,
                pub dispatch_info: extrinsic_failed::DispatchInfo,
            }
            pub mod extrinsic_failed {
                use super::runtime_types;
                pub type DispatchError = runtime_types::sp_runtime::DispatchError;
                pub type DispatchInfo = runtime_types::frame_support::dispatch::DispatchInfo;
            }
            impl ::subxt::events::StaticEvent for ExtrinsicFailed {
                const PALLET: &'static str = "System";
                const EVENT: &'static str = "ExtrinsicFailed";
            }
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            #[doc = "`:code` was updated."]
            pub struct CodeUpdated;
            impl ::subxt::events::StaticEvent for CodeUpdated {
                const PALLET: &'static str = "System";
                const EVENT: &'static str = "CodeUpdated";
            }
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            #[doc = "A new account was created."]
            pub struct NewAccount {
                pub account: new_account::Account,
            }
            pub mod new_account {
                use super::runtime_types;
                pub type Account = ::subxt::utils::AccountId32;
            }
            impl ::subxt::events::StaticEvent for NewAccount {
                const PALLET: &'static str = "System";
                const EVENT: &'static str = "NewAccount";
            }
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            #[doc = "An account was reaped."]
            pub struct KilledAccount {
                pub account: killed_account::Account,
            }
            pub mod killed_account {
                use super::runtime_types;
                pub type Account = ::subxt::utils::AccountId32;
            }
            impl ::subxt::events::StaticEvent for KilledAccount {
                const PALLET: &'static str = "System";
                const EVENT: &'static str = "KilledAccount";
            }
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            #[doc = "On on-chain remark happened."]
            pub struct Remarked {
                pub sender: remarked::Sender,
                pub hash: remarked::Hash,
            }
            pub mod remarked {
                use super::runtime_types;
                pub type Sender = ::subxt::utils::AccountId32;
                pub type Hash = ::subxt::utils::H256;
            }
            impl ::subxt::events::StaticEvent for Remarked {
                const PALLET: &'static str = "System";
                const EVENT: &'static str = "Remarked";
            }
        }
        pub mod storage {
            use super::runtime_types;
            pub mod types {
                use super::runtime_types;
                pub mod account {
                    use super::runtime_types;
                    pub type Account = runtime_types::frame_system::AccountInfo<::core::primitive::u32, ()>;
                    pub type Param0 = ::subxt::utils::AccountId32;
                }
                pub mod extrinsic_count {
                    use super::runtime_types;
                    pub type ExtrinsicCount = ::core::primitive::u32;
                }
                pub mod block_weight {
                    use super::runtime_types;
                    pub type BlockWeight = runtime_types::frame_support::dispatch::PerDispatchClass<
                        runtime_types::sp_weights::weight_v2::Weight,
                    >;
                }
                pub mod all_extrinsics_len {
                    use super::runtime_types;
                    pub type AllExtrinsicsLen = ::core::primitive::u32;
                }
                pub mod block_hash {
                    use super::runtime_types;
                    pub type BlockHash = ::subxt::utils::H256;
                    pub type Param0 = ::core::primitive::u32;
                }
                pub mod extrinsic_data {
                    use super::runtime_types;
                    pub type ExtrinsicData = ::std::vec::Vec<::core::primitive::u8>;
                    pub type Param0 = ::core::primitive::u32;
                }
                pub mod number {
                    use super::runtime_types;
                    pub type Number = ::core::primitive::u32;
                }
                pub mod parent_hash {
                    use super::runtime_types;
                    pub type ParentHash = ::subxt::utils::H256;
                }
                pub mod digest {
                    use super::runtime_types;
                    pub type Digest = runtime_types::sp_runtime::generic::digest::Digest;
                }
                pub mod events {
                    use super::runtime_types;
                    pub type Events = ::std::vec::Vec<
                        runtime_types::frame_system::EventRecord<
                            runtime_types::madara_runtime::RuntimeEvent,
                            ::subxt::utils::H256,
                        >,
                    >;
                }
                pub mod event_count {
                    use super::runtime_types;
                    pub type EventCount = ::core::primitive::u32;
                }
                pub mod event_topics {
                    use super::runtime_types;
                    pub type EventTopics = ::std::vec::Vec<(::core::primitive::u32, ::core::primitive::u32)>;
                    pub type Param0 = ::subxt::utils::H256;
                }
                pub mod last_runtime_upgrade {
                    use super::runtime_types;
                    pub type LastRuntimeUpgrade = runtime_types::frame_system::LastRuntimeUpgradeInfo;
                }
                pub mod upgraded_to_u32_ref_count {
                    use super::runtime_types;
                    pub type UpgradedToU32RefCount = ::core::primitive::bool;
                }
                pub mod upgraded_to_triple_ref_count {
                    use super::runtime_types;
                    pub type UpgradedToTripleRefCount = ::core::primitive::bool;
                }
                pub mod execution_phase {
                    use super::runtime_types;
                    pub type ExecutionPhase = runtime_types::frame_system::Phase;
                }
            }
            pub struct StorageApi;
            impl StorageApi {
                #[doc = " The full account information for a particular account ID."]
                pub fn account_iter(
                    &self,
                ) -> ::subxt::storage::address::Address<
                    (),
                    types::account::Account,
                    (),
                    ::subxt::storage::address::Yes,
                    ::subxt::storage::address::Yes,
                > {
                    ::subxt::storage::address::Address::new_static(
                        "System",
                        "Account",
                        (),
                        [
                            207u8, 128u8, 217u8, 6u8, 244u8, 231u8, 113u8, 230u8, 246u8, 220u8, 226u8, 62u8, 206u8,
                            203u8, 104u8, 119u8, 181u8, 97u8, 211u8, 3u8, 157u8, 102u8, 196u8, 131u8, 51u8, 221u8,
                            41u8, 183u8, 108u8, 28u8, 247u8, 73u8,
                        ],
                    )
                }
                #[doc = " The full account information for a particular account ID."]
                pub fn account(
                    &self,
                    _0: impl ::std::borrow::Borrow<types::account::Param0>,
                ) -> ::subxt::storage::address::Address<
                    ::subxt::storage::address::StaticStorageKey<types::account::Param0>,
                    types::account::Account,
                    ::subxt::storage::address::Yes,
                    ::subxt::storage::address::Yes,
                    (),
                > {
                    ::subxt::storage::address::Address::new_static(
                        "System",
                        "Account",
                        ::subxt::storage::address::StaticStorageKey::new(_0.borrow()),
                        [
                            207u8, 128u8, 217u8, 6u8, 244u8, 231u8, 113u8, 230u8, 246u8, 220u8, 226u8, 62u8, 206u8,
                            203u8, 104u8, 119u8, 181u8, 97u8, 211u8, 3u8, 157u8, 102u8, 196u8, 131u8, 51u8, 221u8,
                            41u8, 183u8, 108u8, 28u8, 247u8, 73u8,
                        ],
                    )
                }
                #[doc = " Total extrinsics count for the current block."]
                pub fn extrinsic_count(
                    &self,
                ) -> ::subxt::storage::address::Address<
                    (),
                    types::extrinsic_count::ExtrinsicCount,
                    ::subxt::storage::address::Yes,
                    (),
                    (),
                > {
                    ::subxt::storage::address::Address::new_static(
                        "System",
                        "ExtrinsicCount",
                        (),
                        [
                            102u8, 76u8, 236u8, 42u8, 40u8, 231u8, 33u8, 222u8, 123u8, 147u8, 153u8, 148u8, 234u8,
                            203u8, 181u8, 119u8, 6u8, 187u8, 177u8, 199u8, 120u8, 47u8, 137u8, 254u8, 96u8, 100u8,
                            165u8, 182u8, 249u8, 230u8, 159u8, 79u8,
                        ],
                    )
                }
                #[doc = " The current weight for the block."]
                pub fn block_weight(
                    &self,
                ) -> ::subxt::storage::address::Address<
                    (),
                    types::block_weight::BlockWeight,
                    ::subxt::storage::address::Yes,
                    ::subxt::storage::address::Yes,
                    (),
                > {
                    ::subxt::storage::address::Address::new_static(
                        "System",
                        "BlockWeight",
                        (),
                        [
                            158u8, 46u8, 228u8, 89u8, 210u8, 214u8, 84u8, 154u8, 50u8, 68u8, 63u8, 62u8, 43u8, 42u8,
                            99u8, 27u8, 54u8, 42u8, 146u8, 44u8, 241u8, 216u8, 229u8, 30u8, 216u8, 255u8, 165u8, 238u8,
                            181u8, 130u8, 36u8, 102u8,
                        ],
                    )
                }
                #[doc = " Total length (in bytes) for all extrinsics put together, for the current block."]
                pub fn all_extrinsics_len(
                    &self,
                ) -> ::subxt::storage::address::Address<
                    (),
                    types::all_extrinsics_len::AllExtrinsicsLen,
                    ::subxt::storage::address::Yes,
                    (),
                    (),
                > {
                    ::subxt::storage::address::Address::new_static(
                        "System",
                        "AllExtrinsicsLen",
                        (),
                        [
                            117u8, 86u8, 61u8, 243u8, 41u8, 51u8, 102u8, 214u8, 137u8, 100u8, 243u8, 185u8, 122u8,
                            174u8, 187u8, 117u8, 86u8, 189u8, 63u8, 135u8, 101u8, 218u8, 203u8, 201u8, 237u8, 254u8,
                            128u8, 183u8, 169u8, 221u8, 242u8, 65u8,
                        ],
                    )
                }
                #[doc = " Map of block numbers to block hashes."]
                pub fn block_hash_iter(
                    &self,
                ) -> ::subxt::storage::address::Address<
                    (),
                    types::block_hash::BlockHash,
                    (),
                    ::subxt::storage::address::Yes,
                    ::subxt::storage::address::Yes,
                > {
                    ::subxt::storage::address::Address::new_static(
                        "System",
                        "BlockHash",
                        (),
                        [
                            217u8, 32u8, 215u8, 253u8, 24u8, 182u8, 207u8, 178u8, 157u8, 24u8, 103u8, 100u8, 195u8,
                            165u8, 69u8, 152u8, 112u8, 181u8, 56u8, 192u8, 164u8, 16u8, 20u8, 222u8, 28u8, 214u8,
                            144u8, 142u8, 146u8, 69u8, 202u8, 118u8,
                        ],
                    )
                }
                #[doc = " Map of block numbers to block hashes."]
                pub fn block_hash(
                    &self,
                    _0: impl ::std::borrow::Borrow<types::block_hash::Param0>,
                ) -> ::subxt::storage::address::Address<
                    ::subxt::storage::address::StaticStorageKey<types::block_hash::Param0>,
                    types::block_hash::BlockHash,
                    ::subxt::storage::address::Yes,
                    ::subxt::storage::address::Yes,
                    (),
                > {
                    ::subxt::storage::address::Address::new_static(
                        "System",
                        "BlockHash",
                        ::subxt::storage::address::StaticStorageKey::new(_0.borrow()),
                        [
                            217u8, 32u8, 215u8, 253u8, 24u8, 182u8, 207u8, 178u8, 157u8, 24u8, 103u8, 100u8, 195u8,
                            165u8, 69u8, 152u8, 112u8, 181u8, 56u8, 192u8, 164u8, 16u8, 20u8, 222u8, 28u8, 214u8,
                            144u8, 142u8, 146u8, 69u8, 202u8, 118u8,
                        ],
                    )
                }
                #[doc = " Extrinsics data for the current block (maps an extrinsic's index to its data)."]
                pub fn extrinsic_data_iter(
                    &self,
                ) -> ::subxt::storage::address::Address<
                    (),
                    types::extrinsic_data::ExtrinsicData,
                    (),
                    ::subxt::storage::address::Yes,
                    ::subxt::storage::address::Yes,
                > {
                    ::subxt::storage::address::Address::new_static(
                        "System",
                        "ExtrinsicData",
                        (),
                        [
                            160u8, 180u8, 122u8, 18u8, 196u8, 26u8, 2u8, 37u8, 115u8, 232u8, 133u8, 220u8, 106u8,
                            245u8, 4u8, 129u8, 42u8, 84u8, 241u8, 45u8, 199u8, 179u8, 128u8, 61u8, 170u8, 137u8, 231u8,
                            156u8, 247u8, 57u8, 47u8, 38u8,
                        ],
                    )
                }
                #[doc = " Extrinsics data for the current block (maps an extrinsic's index to its data)."]
                pub fn extrinsic_data(
                    &self,
                    _0: impl ::std::borrow::Borrow<types::extrinsic_data::Param0>,
                ) -> ::subxt::storage::address::Address<
                    ::subxt::storage::address::StaticStorageKey<types::extrinsic_data::Param0>,
                    types::extrinsic_data::ExtrinsicData,
                    ::subxt::storage::address::Yes,
                    ::subxt::storage::address::Yes,
                    (),
                > {
                    ::subxt::storage::address::Address::new_static(
                        "System",
                        "ExtrinsicData",
                        ::subxt::storage::address::StaticStorageKey::new(_0.borrow()),
                        [
                            160u8, 180u8, 122u8, 18u8, 196u8, 26u8, 2u8, 37u8, 115u8, 232u8, 133u8, 220u8, 106u8,
                            245u8, 4u8, 129u8, 42u8, 84u8, 241u8, 45u8, 199u8, 179u8, 128u8, 61u8, 170u8, 137u8, 231u8,
                            156u8, 247u8, 57u8, 47u8, 38u8,
                        ],
                    )
                }
                #[doc = " The current block number being processed. Set by `execute_block`."]
                pub fn number(
                    &self,
                ) -> ::subxt::storage::address::Address<
                    (),
                    types::number::Number,
                    ::subxt::storage::address::Yes,
                    ::subxt::storage::address::Yes,
                    (),
                > {
                    ::subxt::storage::address::Address::new_static(
                        "System",
                        "Number",
                        (),
                        [
                            30u8, 194u8, 177u8, 90u8, 194u8, 232u8, 46u8, 180u8, 85u8, 129u8, 14u8, 9u8, 8u8, 8u8,
                            23u8, 95u8, 230u8, 5u8, 13u8, 105u8, 125u8, 2u8, 22u8, 200u8, 78u8, 93u8, 115u8, 28u8,
                            150u8, 113u8, 48u8, 53u8,
                        ],
                    )
                }
                #[doc = " Hash of the previous block."]
                pub fn parent_hash(
                    &self,
                ) -> ::subxt::storage::address::Address<
                    (),
                    types::parent_hash::ParentHash,
                    ::subxt::storage::address::Yes,
                    ::subxt::storage::address::Yes,
                    (),
                > {
                    ::subxt::storage::address::Address::new_static(
                        "System",
                        "ParentHash",
                        (),
                        [
                            26u8, 130u8, 11u8, 216u8, 155u8, 71u8, 128u8, 170u8, 30u8, 153u8, 21u8, 192u8, 62u8, 93u8,
                            137u8, 80u8, 120u8, 81u8, 202u8, 94u8, 248u8, 125u8, 71u8, 82u8, 141u8, 229u8, 32u8, 56u8,
                            73u8, 50u8, 101u8, 78u8,
                        ],
                    )
                }
                #[doc = " Digest of the current block, also part of the block header."]
                pub fn digest(
                    &self,
                ) -> ::subxt::storage::address::Address<
                    (),
                    types::digest::Digest,
                    ::subxt::storage::address::Yes,
                    ::subxt::storage::address::Yes,
                    (),
                > {
                    ::subxt::storage::address::Address::new_static(
                        "System",
                        "Digest",
                        (),
                        [
                            61u8, 64u8, 237u8, 91u8, 145u8, 232u8, 17u8, 254u8, 181u8, 16u8, 234u8, 91u8, 51u8, 140u8,
                            254u8, 131u8, 98u8, 135u8, 21u8, 37u8, 251u8, 20u8, 58u8, 92u8, 123u8, 141u8, 14u8, 227u8,
                            146u8, 46u8, 222u8, 117u8,
                        ],
                    )
                }
                #[doc = " Events deposited for the current block."]
                #[doc = ""]
                #[doc = " NOTE: The item is unbound and should therefore never be read on chain."]
                #[doc = " It could otherwise inflate the PoV size of a block."]
                #[doc = ""]
                #[doc = " Events have a large in-memory size. Box the events to not go out-of-memory"]
                #[doc = " just in case someone still reads them from within the runtime."]
                pub fn events(
                    &self,
                ) -> ::subxt::storage::address::Address<
                    (),
                    types::events::Events,
                    ::subxt::storage::address::Yes,
                    ::subxt::storage::address::Yes,
                    (),
                > {
                    ::subxt::storage::address::Address::new_static(
                        "System",
                        "Events",
                        (),
                        [
                            255u8, 169u8, 249u8, 70u8, 39u8, 153u8, 238u8, 39u8, 195u8, 196u8, 92u8, 84u8, 82u8, 162u8,
                            155u8, 174u8, 44u8, 174u8, 242u8, 82u8, 193u8, 130u8, 148u8, 194u8, 182u8, 64u8, 126u8,
                            65u8, 148u8, 199u8, 233u8, 124u8,
                        ],
                    )
                }
                #[doc = " The number of events in the `Events<T>` list."]
                pub fn event_count(
                    &self,
                ) -> ::subxt::storage::address::Address<
                    (),
                    types::event_count::EventCount,
                    ::subxt::storage::address::Yes,
                    ::subxt::storage::address::Yes,
                    (),
                > {
                    ::subxt::storage::address::Address::new_static(
                        "System",
                        "EventCount",
                        (),
                        [
                            175u8, 24u8, 252u8, 184u8, 210u8, 167u8, 146u8, 143u8, 164u8, 80u8, 151u8, 205u8, 189u8,
                            189u8, 55u8, 220u8, 47u8, 101u8, 181u8, 33u8, 254u8, 131u8, 13u8, 143u8, 3u8, 244u8, 245u8,
                            45u8, 2u8, 210u8, 79u8, 133u8,
                        ],
                    )
                }
                #[doc = " Mapping between a topic (represented by T::Hash) and a vector of indexes"]
                #[doc = " of events in the `<Events<T>>` list."]
                #[doc = ""]
                #[doc = " All topic vectors have deterministic storage locations depending on the topic. This"]
                #[doc = " allows light-clients to leverage the changes trie storage tracking mechanism and"]
                #[doc = " in case of changes fetch the list of events of interest."]
                #[doc = ""]
                #[doc = " The value has the type `(BlockNumberFor<T>, EventIndex)` because if we used only just"]
                #[doc = " the `EventIndex` then in case if the topic has the same contents on the next block"]
                #[doc = " no notification will be triggered thus the event might be lost."]
                pub fn event_topics_iter(
                    &self,
                ) -> ::subxt::storage::address::Address<
                    (),
                    types::event_topics::EventTopics,
                    (),
                    ::subxt::storage::address::Yes,
                    ::subxt::storage::address::Yes,
                > {
                    ::subxt::storage::address::Address::new_static(
                        "System",
                        "EventTopics",
                        (),
                        [
                            40u8, 225u8, 14u8, 75u8, 44u8, 176u8, 76u8, 34u8, 143u8, 107u8, 69u8, 133u8, 114u8, 13u8,
                            172u8, 250u8, 141u8, 73u8, 12u8, 65u8, 217u8, 63u8, 120u8, 241u8, 48u8, 106u8, 143u8,
                            161u8, 128u8, 100u8, 166u8, 59u8,
                        ],
                    )
                }
                #[doc = " Mapping between a topic (represented by T::Hash) and a vector of indexes"]
                #[doc = " of events in the `<Events<T>>` list."]
                #[doc = ""]
                #[doc = " All topic vectors have deterministic storage locations depending on the topic. This"]
                #[doc = " allows light-clients to leverage the changes trie storage tracking mechanism and"]
                #[doc = " in case of changes fetch the list of events of interest."]
                #[doc = ""]
                #[doc = " The value has the type `(BlockNumberFor<T>, EventIndex)` because if we used only just"]
                #[doc = " the `EventIndex` then in case if the topic has the same contents on the next block"]
                #[doc = " no notification will be triggered thus the event might be lost."]
                pub fn event_topics(
                    &self,
                    _0: impl ::std::borrow::Borrow<types::event_topics::Param0>,
                ) -> ::subxt::storage::address::Address<
                    ::subxt::storage::address::StaticStorageKey<types::event_topics::Param0>,
                    types::event_topics::EventTopics,
                    ::subxt::storage::address::Yes,
                    ::subxt::storage::address::Yes,
                    (),
                > {
                    ::subxt::storage::address::Address::new_static(
                        "System",
                        "EventTopics",
                        ::subxt::storage::address::StaticStorageKey::new(_0.borrow()),
                        [
                            40u8, 225u8, 14u8, 75u8, 44u8, 176u8, 76u8, 34u8, 143u8, 107u8, 69u8, 133u8, 114u8, 13u8,
                            172u8, 250u8, 141u8, 73u8, 12u8, 65u8, 217u8, 63u8, 120u8, 241u8, 48u8, 106u8, 143u8,
                            161u8, 128u8, 100u8, 166u8, 59u8,
                        ],
                    )
                }
                #[doc = " Stores the `spec_version` and `spec_name` of when the last runtime upgrade happened."]
                pub fn last_runtime_upgrade(
                    &self,
                ) -> ::subxt::storage::address::Address<
                    (),
                    types::last_runtime_upgrade::LastRuntimeUpgrade,
                    ::subxt::storage::address::Yes,
                    (),
                    (),
                > {
                    ::subxt::storage::address::Address::new_static(
                        "System",
                        "LastRuntimeUpgrade",
                        (),
                        [
                            137u8, 29u8, 175u8, 75u8, 197u8, 208u8, 91u8, 207u8, 156u8, 87u8, 148u8, 68u8, 91u8, 140u8,
                            22u8, 233u8, 1u8, 229u8, 56u8, 34u8, 40u8, 194u8, 253u8, 30u8, 163u8, 39u8, 54u8, 209u8,
                            13u8, 27u8, 139u8, 184u8,
                        ],
                    )
                }
                #[doc = " True if we have upgraded so that `type RefCount` is `u32`. False (default) if not."]
                pub fn upgraded_to_u32_ref_count(
                    &self,
                ) -> ::subxt::storage::address::Address<
                    (),
                    types::upgraded_to_u32_ref_count::UpgradedToU32RefCount,
                    ::subxt::storage::address::Yes,
                    ::subxt::storage::address::Yes,
                    (),
                > {
                    ::subxt::storage::address::Address::new_static(
                        "System",
                        "UpgradedToU32RefCount",
                        (),
                        [
                            229u8, 73u8, 9u8, 132u8, 186u8, 116u8, 151u8, 171u8, 145u8, 29u8, 34u8, 130u8, 52u8, 146u8,
                            124u8, 175u8, 79u8, 189u8, 147u8, 230u8, 234u8, 107u8, 124u8, 31u8, 2u8, 22u8, 86u8, 190u8,
                            4u8, 147u8, 50u8, 245u8,
                        ],
                    )
                }
                #[doc = " True if we have upgraded so that AccountInfo contains three types of `RefCount`. False"]
                #[doc = " (default) if not."]
                pub fn upgraded_to_triple_ref_count(
                    &self,
                ) -> ::subxt::storage::address::Address<
                    (),
                    types::upgraded_to_triple_ref_count::UpgradedToTripleRefCount,
                    ::subxt::storage::address::Yes,
                    ::subxt::storage::address::Yes,
                    (),
                > {
                    ::subxt::storage::address::Address::new_static(
                        "System",
                        "UpgradedToTripleRefCount",
                        (),
                        [
                            97u8, 66u8, 124u8, 243u8, 27u8, 167u8, 147u8, 81u8, 254u8, 201u8, 101u8, 24u8, 40u8, 231u8,
                            14u8, 179u8, 154u8, 163u8, 71u8, 81u8, 185u8, 167u8, 82u8, 254u8, 189u8, 3u8, 101u8, 207u8,
                            206u8, 194u8, 155u8, 151u8,
                        ],
                    )
                }
                #[doc = " The execution phase of the block."]
                pub fn execution_phase(
                    &self,
                ) -> ::subxt::storage::address::Address<
                    (),
                    types::execution_phase::ExecutionPhase,
                    ::subxt::storage::address::Yes,
                    (),
                    (),
                > {
                    ::subxt::storage::address::Address::new_static(
                        "System",
                        "ExecutionPhase",
                        (),
                        [
                            191u8, 129u8, 100u8, 134u8, 126u8, 116u8, 154u8, 203u8, 220u8, 200u8, 0u8, 26u8, 161u8,
                            250u8, 133u8, 205u8, 146u8, 24u8, 5u8, 156u8, 158u8, 35u8, 36u8, 253u8, 52u8, 235u8, 86u8,
                            167u8, 35u8, 100u8, 119u8, 27u8,
                        ],
                    )
                }
            }
        }
        pub mod constants {
            use super::runtime_types;
            pub struct ConstantsApi;
            impl ConstantsApi {
                #[doc = " Block & extrinsics weights: base values and limits."]
                pub fn block_weights(
                    &self,
                ) -> ::subxt::constants::Address<runtime_types::frame_system::limits::BlockWeights> {
                    ::subxt::constants::Address::new_static(
                        "System",
                        "BlockWeights",
                        [
                            176u8, 124u8, 225u8, 136u8, 25u8, 73u8, 247u8, 33u8, 82u8, 206u8, 85u8, 190u8, 127u8,
                            102u8, 71u8, 11u8, 185u8, 8u8, 58u8, 0u8, 94u8, 55u8, 163u8, 177u8, 104u8, 59u8, 60u8,
                            136u8, 246u8, 116u8, 0u8, 239u8,
                        ],
                    )
                }
                #[doc = " The maximum length of a block (in bytes)."]
                pub fn block_length(
                    &self,
                ) -> ::subxt::constants::Address<runtime_types::frame_system::limits::BlockLength> {
                    ::subxt::constants::Address::new_static(
                        "System",
                        "BlockLength",
                        [
                            23u8, 242u8, 225u8, 39u8, 225u8, 67u8, 152u8, 41u8, 155u8, 104u8, 68u8, 229u8, 185u8,
                            133u8, 10u8, 143u8, 184u8, 152u8, 234u8, 44u8, 140u8, 96u8, 166u8, 235u8, 162u8, 160u8,
                            72u8, 7u8, 35u8, 194u8, 3u8, 37u8,
                        ],
                    )
                }
                #[doc = " Maximum number of block number to block hash mappings to keep (oldest pruned first)."]
                pub fn block_hash_count(&self) -> ::subxt::constants::Address<::core::primitive::u32> {
                    ::subxt::constants::Address::new_static(
                        "System",
                        "BlockHashCount",
                        [
                            98u8, 252u8, 116u8, 72u8, 26u8, 180u8, 225u8, 83u8, 200u8, 157u8, 125u8, 151u8, 53u8, 76u8,
                            168u8, 26u8, 10u8, 9u8, 98u8, 68u8, 9u8, 178u8, 197u8, 113u8, 31u8, 79u8, 200u8, 90u8,
                            203u8, 100u8, 41u8, 145u8,
                        ],
                    )
                }
                #[doc = " The weight of runtime database operations the runtime can invoke."]
                pub fn db_weight(&self) -> ::subxt::constants::Address<runtime_types::sp_weights::RuntimeDbWeight> {
                    ::subxt::constants::Address::new_static(
                        "System",
                        "DbWeight",
                        [
                            42u8, 43u8, 178u8, 142u8, 243u8, 203u8, 60u8, 173u8, 118u8, 111u8, 200u8, 170u8, 102u8,
                            70u8, 237u8, 187u8, 198u8, 120u8, 153u8, 232u8, 183u8, 76u8, 74u8, 10u8, 70u8, 243u8, 14u8,
                            218u8, 213u8, 126u8, 29u8, 177u8,
                        ],
                    )
                }
                #[doc = " Get the chain's current version."]
                pub fn version(&self) -> ::subxt::constants::Address<runtime_types::sp_version::RuntimeVersion> {
                    ::subxt::constants::Address::new_static(
                        "System",
                        "Version",
                        [
                            219u8, 45u8, 162u8, 245u8, 177u8, 246u8, 48u8, 126u8, 191u8, 157u8, 228u8, 83u8, 111u8,
                            133u8, 183u8, 13u8, 148u8, 108u8, 92u8, 102u8, 72u8, 205u8, 74u8, 242u8, 233u8, 79u8, 20u8,
                            170u8, 72u8, 202u8, 158u8, 165u8,
                        ],
                    )
                }
                #[doc = " The designated SS58 prefix of this chain."]
                #[doc = ""]
                #[doc = " This replaces the \"ss58Format\" property declared in the chain spec. Reason is"]
                #[doc = " that the runtime should know about the prefix in order to make use of it as"]
                #[doc = " an identifier of the chain."]
                pub fn ss58_prefix(&self) -> ::subxt::constants::Address<::core::primitive::u16> {
                    ::subxt::constants::Address::new_static(
                        "System",
                        "SS58Prefix",
                        [
                            116u8, 33u8, 2u8, 170u8, 181u8, 147u8, 171u8, 169u8, 167u8, 227u8, 41u8, 144u8, 11u8,
                            236u8, 82u8, 100u8, 74u8, 60u8, 184u8, 72u8, 169u8, 90u8, 208u8, 135u8, 15u8, 117u8, 10u8,
                            123u8, 128u8, 193u8, 29u8, 70u8,
                        ],
                    )
                }
            }
        }
    }
    pub mod timestamp {
        use super::root_mod;
        use super::runtime_types;
        #[doc = "Contains a variant per dispatchable extrinsic that this pallet has."]
        pub type Call = runtime_types::pallet_timestamp::pallet::Call;
        pub mod calls {
            use super::root_mod;
            use super::runtime_types;
            type DispatchError = runtime_types::sp_runtime::DispatchError;
            pub mod types {
                use super::runtime_types;
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                #[doc = "See [`Pallet::set`]."]
                pub struct Set {
                    #[codec(compact)]
                    pub now: set::Now,
                }
                pub mod set {
                    use super::runtime_types;
                    pub type Now = ::core::primitive::u64;
                }
                impl ::subxt::blocks::StaticExtrinsic for Set {
                    const PALLET: &'static str = "Timestamp";
                    const CALL: &'static str = "set";
                }
            }
            pub struct TransactionApi;
            impl TransactionApi {
                #[doc = "See [`Pallet::set`]."]
                pub fn set(&self, now: types::set::Now) -> ::subxt::tx::Payload<types::Set> {
                    ::subxt::tx::Payload::new_static(
                        "Timestamp",
                        "set",
                        types::Set { now },
                        [
                            37u8, 95u8, 49u8, 218u8, 24u8, 22u8, 0u8, 95u8, 72u8, 35u8, 155u8, 199u8, 213u8, 54u8,
                            207u8, 22u8, 185u8, 193u8, 221u8, 70u8, 18u8, 200u8, 4u8, 231u8, 195u8, 173u8, 6u8, 122u8,
                            11u8, 203u8, 231u8, 227u8,
                        ],
                    )
                }
            }
        }
        pub mod storage {
            use super::runtime_types;
            pub mod types {
                use super::runtime_types;
                pub mod now {
                    use super::runtime_types;
                    pub type Now = ::core::primitive::u64;
                }
                pub mod did_update {
                    use super::runtime_types;
                    pub type DidUpdate = ::core::primitive::bool;
                }
            }
            pub struct StorageApi;
            impl StorageApi {
                #[doc = " The current time for the current block."]
                pub fn now(
                    &self,
                ) -> ::subxt::storage::address::Address<
                    (),
                    types::now::Now,
                    ::subxt::storage::address::Yes,
                    ::subxt::storage::address::Yes,
                    (),
                > {
                    ::subxt::storage::address::Address::new_static(
                        "Timestamp",
                        "Now",
                        (),
                        [
                            44u8, 50u8, 80u8, 30u8, 195u8, 146u8, 123u8, 238u8, 8u8, 163u8, 187u8, 92u8, 61u8, 39u8,
                            51u8, 29u8, 173u8, 169u8, 217u8, 158u8, 85u8, 187u8, 141u8, 26u8, 12u8, 115u8, 51u8, 11u8,
                            200u8, 244u8, 138u8, 152u8,
                        ],
                    )
                }
                #[doc = " Whether the timestamp has been updated in this block."]
                #[doc = ""]
                #[doc = " This value is updated to `true` upon successful submission of a timestamp by a node."]
                #[doc = " It is then checked at the end of each block execution in the `on_finalize` hook."]
                pub fn did_update(
                    &self,
                ) -> ::subxt::storage::address::Address<
                    (),
                    types::did_update::DidUpdate,
                    ::subxt::storage::address::Yes,
                    ::subxt::storage::address::Yes,
                    (),
                > {
                    ::subxt::storage::address::Address::new_static(
                        "Timestamp",
                        "DidUpdate",
                        (),
                        [
                            229u8, 175u8, 246u8, 102u8, 237u8, 158u8, 212u8, 229u8, 238u8, 214u8, 205u8, 160u8, 164u8,
                            252u8, 195u8, 75u8, 139u8, 110u8, 22u8, 34u8, 248u8, 204u8, 107u8, 46u8, 20u8, 200u8,
                            238u8, 167u8, 71u8, 41u8, 214u8, 140u8,
                        ],
                    )
                }
            }
        }
        pub mod constants {
            use super::runtime_types;
            pub struct ConstantsApi;
            impl ConstantsApi {
                #[doc = " The minimum period between blocks."]
                #[doc = ""]
                #[doc = " Be aware that this is different to the *expected* period that the block production"]
                #[doc = " apparatus provides. Your chosen consensus system will generally work with this to"]
                #[doc = " determine a sensible block time. For example, in the Aura pallet it will be double this"]
                #[doc = " period on default settings."]
                pub fn minimum_period(&self) -> ::subxt::constants::Address<::core::primitive::u64> {
                    ::subxt::constants::Address::new_static(
                        "Timestamp",
                        "MinimumPeriod",
                        [
                            128u8, 214u8, 205u8, 242u8, 181u8, 142u8, 124u8, 231u8, 190u8, 146u8, 59u8, 226u8, 157u8,
                            101u8, 103u8, 117u8, 249u8, 65u8, 18u8, 191u8, 103u8, 119u8, 53u8, 85u8, 81u8, 96u8, 220u8,
                            42u8, 184u8, 239u8, 42u8, 246u8,
                        ],
                    )
                }
            }
        }
    }
    pub mod aura {
        use super::root_mod;
        use super::runtime_types;
        pub mod storage {
            use super::runtime_types;
            pub mod types {
                use super::runtime_types;
                pub mod authorities {
                    use super::runtime_types;
                    pub type Authorities = runtime_types::bounded_collections::bounded_vec::BoundedVec<
                        runtime_types::sp_consensus_aura::sr25519::app_sr25519::Public,
                    >;
                }
                pub mod current_slot {
                    use super::runtime_types;
                    pub type CurrentSlot = runtime_types::sp_consensus_slots::Slot;
                }
            }
            pub struct StorageApi;
            impl StorageApi {
                #[doc = " The current authority set."]
                pub fn authorities(
                    &self,
                ) -> ::subxt::storage::address::Address<
                    (),
                    types::authorities::Authorities,
                    ::subxt::storage::address::Yes,
                    ::subxt::storage::address::Yes,
                    (),
                > {
                    ::subxt::storage::address::Address::new_static(
                        "Aura",
                        "Authorities",
                        (),
                        [
                            232u8, 129u8, 167u8, 104u8, 47u8, 188u8, 238u8, 164u8, 6u8, 29u8, 129u8, 45u8, 64u8, 182u8,
                            194u8, 47u8, 0u8, 73u8, 63u8, 102u8, 204u8, 94u8, 111u8, 96u8, 137u8, 7u8, 141u8, 110u8,
                            180u8, 80u8, 228u8, 16u8,
                        ],
                    )
                }
                #[doc = " The current slot of this block."]
                #[doc = ""]
                #[doc = " This will be set in `on_initialize`."]
                pub fn current_slot(
                    &self,
                ) -> ::subxt::storage::address::Address<
                    (),
                    types::current_slot::CurrentSlot,
                    ::subxt::storage::address::Yes,
                    ::subxt::storage::address::Yes,
                    (),
                > {
                    ::subxt::storage::address::Address::new_static(
                        "Aura",
                        "CurrentSlot",
                        (),
                        [
                            112u8, 199u8, 115u8, 248u8, 217u8, 242u8, 45u8, 231u8, 178u8, 53u8, 236u8, 167u8, 219u8,
                            238u8, 81u8, 243u8, 39u8, 140u8, 68u8, 19u8, 201u8, 169u8, 211u8, 133u8, 135u8, 213u8,
                            150u8, 105u8, 60u8, 252u8, 43u8, 57u8,
                        ],
                    )
                }
            }
        }
    }
    pub mod grandpa {
        use super::root_mod;
        use super::runtime_types;
        #[doc = "The `Error` enum of this pallet."]
        pub type Error = runtime_types::pallet_grandpa::pallet::Error;
        #[doc = "Contains a variant per dispatchable extrinsic that this pallet has."]
        pub type Call = runtime_types::pallet_grandpa::pallet::Call;
        pub mod calls {
            use super::root_mod;
            use super::runtime_types;
            type DispatchError = runtime_types::sp_runtime::DispatchError;
            pub mod types {
                use super::runtime_types;
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                #[doc = "See [`Pallet::report_equivocation`]."]
                pub struct ReportEquivocation {
                    pub equivocation_proof: ::std::boxed::Box<report_equivocation::EquivocationProof>,
                    pub key_owner_proof: report_equivocation::KeyOwnerProof,
                }
                pub mod report_equivocation {
                    use super::runtime_types;
                    pub type EquivocationProof = runtime_types::sp_consensus_grandpa::EquivocationProof<
                        ::subxt::utils::H256,
                        ::core::primitive::u32,
                    >;
                    pub type KeyOwnerProof = runtime_types::sp_core::Void;
                }
                impl ::subxt::blocks::StaticExtrinsic for ReportEquivocation {
                    const PALLET: &'static str = "Grandpa";
                    const CALL: &'static str = "report_equivocation";
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                #[doc = "See [`Pallet::report_equivocation_unsigned`]."]
                pub struct ReportEquivocationUnsigned {
                    pub equivocation_proof: ::std::boxed::Box<report_equivocation_unsigned::EquivocationProof>,
                    pub key_owner_proof: report_equivocation_unsigned::KeyOwnerProof,
                }
                pub mod report_equivocation_unsigned {
                    use super::runtime_types;
                    pub type EquivocationProof = runtime_types::sp_consensus_grandpa::EquivocationProof<
                        ::subxt::utils::H256,
                        ::core::primitive::u32,
                    >;
                    pub type KeyOwnerProof = runtime_types::sp_core::Void;
                }
                impl ::subxt::blocks::StaticExtrinsic for ReportEquivocationUnsigned {
                    const PALLET: &'static str = "Grandpa";
                    const CALL: &'static str = "report_equivocation_unsigned";
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                #[doc = "See [`Pallet::note_stalled`]."]
                pub struct NoteStalled {
                    pub delay: note_stalled::Delay,
                    pub best_finalized_block_number: note_stalled::BestFinalizedBlockNumber,
                }
                pub mod note_stalled {
                    use super::runtime_types;
                    pub type Delay = ::core::primitive::u32;
                    pub type BestFinalizedBlockNumber = ::core::primitive::u32;
                }
                impl ::subxt::blocks::StaticExtrinsic for NoteStalled {
                    const PALLET: &'static str = "Grandpa";
                    const CALL: &'static str = "note_stalled";
                }
            }
            pub struct TransactionApi;
            impl TransactionApi {
                #[doc = "See [`Pallet::report_equivocation`]."]
                pub fn report_equivocation(
                    &self,
                    equivocation_proof: types::report_equivocation::EquivocationProof,
                    key_owner_proof: types::report_equivocation::KeyOwnerProof,
                ) -> ::subxt::tx::Payload<types::ReportEquivocation> {
                    ::subxt::tx::Payload::new_static(
                        "Grandpa",
                        "report_equivocation",
                        types::ReportEquivocation {
                            equivocation_proof: ::std::boxed::Box::new(equivocation_proof),
                            key_owner_proof,
                        },
                        [
                            158u8, 70u8, 189u8, 51u8, 231u8, 191u8, 199u8, 33u8, 64u8, 156u8, 71u8, 243u8, 122u8,
                            199u8, 216u8, 10u8, 45u8, 73u8, 198u8, 141u8, 31u8, 209u8, 58u8, 164u8, 219u8, 124u8,
                            242u8, 26u8, 114u8, 52u8, 65u8, 106u8,
                        ],
                    )
                }
                #[doc = "See [`Pallet::report_equivocation_unsigned`]."]
                pub fn report_equivocation_unsigned(
                    &self,
                    equivocation_proof: types::report_equivocation_unsigned::EquivocationProof,
                    key_owner_proof: types::report_equivocation_unsigned::KeyOwnerProof,
                ) -> ::subxt::tx::Payload<types::ReportEquivocationUnsigned> {
                    ::subxt::tx::Payload::new_static(
                        "Grandpa",
                        "report_equivocation_unsigned",
                        types::ReportEquivocationUnsigned {
                            equivocation_proof: ::std::boxed::Box::new(equivocation_proof),
                            key_owner_proof,
                        },
                        [
                            53u8, 23u8, 255u8, 215u8, 105u8, 11u8, 67u8, 177u8, 234u8, 248u8, 183u8, 57u8, 230u8,
                            239u8, 54u8, 238u8, 115u8, 170u8, 153u8, 18u8, 55u8, 195u8, 85u8, 98u8, 109u8, 194u8, 57u8,
                            225u8, 139u8, 237u8, 171u8, 152u8,
                        ],
                    )
                }
                #[doc = "See [`Pallet::note_stalled`]."]
                pub fn note_stalled(
                    &self,
                    delay: types::note_stalled::Delay,
                    best_finalized_block_number: types::note_stalled::BestFinalizedBlockNumber,
                ) -> ::subxt::tx::Payload<types::NoteStalled> {
                    ::subxt::tx::Payload::new_static(
                        "Grandpa",
                        "note_stalled",
                        types::NoteStalled { delay, best_finalized_block_number },
                        [
                            158u8, 25u8, 64u8, 114u8, 131u8, 139u8, 227u8, 132u8, 42u8, 107u8, 40u8, 249u8, 18u8, 93u8,
                            254u8, 86u8, 37u8, 67u8, 250u8, 35u8, 241u8, 194u8, 209u8, 20u8, 39u8, 75u8, 186u8, 21u8,
                            48u8, 124u8, 151u8, 31u8,
                        ],
                    )
                }
            }
        }
        #[doc = "The `Event` enum of this pallet"]
        pub type Event = runtime_types::pallet_grandpa::pallet::Event;
        pub mod events {
            use super::runtime_types;
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            #[doc = "New authority set has been applied."]
            pub struct NewAuthorities {
                pub authority_set: new_authorities::AuthoritySet,
            }
            pub mod new_authorities {
                use super::runtime_types;
                pub type AuthoritySet =
                    ::std::vec::Vec<(runtime_types::sp_consensus_grandpa::app::Public, ::core::primitive::u64)>;
            }
            impl ::subxt::events::StaticEvent for NewAuthorities {
                const PALLET: &'static str = "Grandpa";
                const EVENT: &'static str = "NewAuthorities";
            }
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            #[doc = "Current authority set has been paused."]
            pub struct Paused;
            impl ::subxt::events::StaticEvent for Paused {
                const PALLET: &'static str = "Grandpa";
                const EVENT: &'static str = "Paused";
            }
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            #[doc = "Current authority set has been resumed."]
            pub struct Resumed;
            impl ::subxt::events::StaticEvent for Resumed {
                const PALLET: &'static str = "Grandpa";
                const EVENT: &'static str = "Resumed";
            }
        }
        pub mod storage {
            use super::runtime_types;
            pub mod types {
                use super::runtime_types;
                pub mod state {
                    use super::runtime_types;
                    pub type State = runtime_types::pallet_grandpa::StoredState<::core::primitive::u32>;
                }
                pub mod pending_change {
                    use super::runtime_types;
                    pub type PendingChange = runtime_types::pallet_grandpa::StoredPendingChange<::core::primitive::u32>;
                }
                pub mod next_forced {
                    use super::runtime_types;
                    pub type NextForced = ::core::primitive::u32;
                }
                pub mod stalled {
                    use super::runtime_types;
                    pub type Stalled = (::core::primitive::u32, ::core::primitive::u32);
                }
                pub mod current_set_id {
                    use super::runtime_types;
                    pub type CurrentSetId = ::core::primitive::u64;
                }
                pub mod set_id_session {
                    use super::runtime_types;
                    pub type SetIdSession = ::core::primitive::u32;
                    pub type Param0 = ::core::primitive::u64;
                }
            }
            pub struct StorageApi;
            impl StorageApi {
                #[doc = " State of the current authority set."]
                pub fn state(
                    &self,
                ) -> ::subxt::storage::address::Address<
                    (),
                    types::state::State,
                    ::subxt::storage::address::Yes,
                    ::subxt::storage::address::Yes,
                    (),
                > {
                    ::subxt::storage::address::Address::new_static(
                        "Grandpa",
                        "State",
                        (),
                        [
                            73u8, 71u8, 112u8, 83u8, 238u8, 75u8, 44u8, 9u8, 180u8, 33u8, 30u8, 121u8, 98u8, 96u8,
                            61u8, 133u8, 16u8, 70u8, 30u8, 249u8, 34u8, 148u8, 15u8, 239u8, 164u8, 157u8, 52u8, 27u8,
                            144u8, 52u8, 223u8, 109u8,
                        ],
                    )
                }
                #[doc = " Pending change: (signaled at, scheduled change)."]
                pub fn pending_change(
                    &self,
                ) -> ::subxt::storage::address::Address<
                    (),
                    types::pending_change::PendingChange,
                    ::subxt::storage::address::Yes,
                    (),
                    (),
                > {
                    ::subxt::storage::address::Address::new_static(
                        "Grandpa",
                        "PendingChange",
                        (),
                        [
                            150u8, 194u8, 185u8, 248u8, 239u8, 43u8, 141u8, 253u8, 61u8, 106u8, 74u8, 164u8, 209u8,
                            204u8, 206u8, 200u8, 32u8, 38u8, 11u8, 78u8, 84u8, 243u8, 181u8, 142u8, 179u8, 151u8, 81u8,
                            204u8, 244u8, 150u8, 137u8, 250u8,
                        ],
                    )
                }
                #[doc = " next block number where we can force a change."]
                pub fn next_forced(
                    &self,
                ) -> ::subxt::storage::address::Address<
                    (),
                    types::next_forced::NextForced,
                    ::subxt::storage::address::Yes,
                    (),
                    (),
                > {
                    ::subxt::storage::address::Address::new_static(
                        "Grandpa",
                        "NextForced",
                        (),
                        [
                            3u8, 231u8, 56u8, 18u8, 87u8, 112u8, 227u8, 126u8, 180u8, 131u8, 255u8, 141u8, 82u8, 34u8,
                            61u8, 47u8, 234u8, 37u8, 95u8, 62u8, 33u8, 235u8, 231u8, 122u8, 125u8, 8u8, 223u8, 95u8,
                            255u8, 204u8, 40u8, 97u8,
                        ],
                    )
                }
                #[doc = " `true` if we are currently stalled."]
                pub fn stalled(
                    &self,
                ) -> ::subxt::storage::address::Address<
                    (),
                    types::stalled::Stalled,
                    ::subxt::storage::address::Yes,
                    (),
                    (),
                > {
                    ::subxt::storage::address::Address::new_static(
                        "Grandpa",
                        "Stalled",
                        (),
                        [
                            6u8, 81u8, 205u8, 142u8, 195u8, 48u8, 0u8, 247u8, 108u8, 170u8, 10u8, 249u8, 72u8, 206u8,
                            32u8, 103u8, 109u8, 57u8, 51u8, 21u8, 144u8, 204u8, 79u8, 8u8, 191u8, 185u8, 38u8, 34u8,
                            118u8, 223u8, 75u8, 241u8,
                        ],
                    )
                }
                #[doc = " The number of changes (both in terms of keys and underlying economic responsibilities)"]
                #[doc = " in the \"set\" of Grandpa validators from genesis."]
                pub fn current_set_id(
                    &self,
                ) -> ::subxt::storage::address::Address<
                    (),
                    types::current_set_id::CurrentSetId,
                    ::subxt::storage::address::Yes,
                    ::subxt::storage::address::Yes,
                    (),
                > {
                    ::subxt::storage::address::Address::new_static(
                        "Grandpa",
                        "CurrentSetId",
                        (),
                        [
                            234u8, 215u8, 218u8, 42u8, 30u8, 76u8, 129u8, 40u8, 125u8, 137u8, 207u8, 47u8, 46u8, 213u8,
                            159u8, 50u8, 175u8, 81u8, 155u8, 123u8, 246u8, 175u8, 156u8, 68u8, 22u8, 113u8, 135u8,
                            137u8, 163u8, 18u8, 115u8, 73u8,
                        ],
                    )
                }
                #[doc = " A mapping from grandpa set ID to the index of the *most recent* session for which its"]
                #[doc = " members were responsible."]
                #[doc = ""]
                #[doc = " This is only used for validating equivocation proofs. An equivocation proof must"]
                #[doc = " contains a key-ownership proof for a given session, therefore we need a way to tie"]
                #[doc = " together sessions and GRANDPA set ids, i.e. we need to validate that a validator"]
                #[doc = " was the owner of a given key on a given session, and what the active set ID was"]
                #[doc = " during that session."]
                #[doc = ""]
                #[doc = " TWOX-NOTE: `SetId` is not under user control."]
                pub fn set_id_session_iter(
                    &self,
                ) -> ::subxt::storage::address::Address<
                    (),
                    types::set_id_session::SetIdSession,
                    (),
                    (),
                    ::subxt::storage::address::Yes,
                > {
                    ::subxt::storage::address::Address::new_static(
                        "Grandpa",
                        "SetIdSession",
                        (),
                        [
                            47u8, 0u8, 239u8, 121u8, 187u8, 213u8, 254u8, 50u8, 238u8, 10u8, 162u8, 65u8, 189u8, 166u8,
                            37u8, 74u8, 82u8, 81u8, 160u8, 20u8, 180u8, 253u8, 238u8, 18u8, 209u8, 203u8, 38u8, 148u8,
                            16u8, 105u8, 72u8, 169u8,
                        ],
                    )
                }
                #[doc = " A mapping from grandpa set ID to the index of the *most recent* session for which its"]
                #[doc = " members were responsible."]
                #[doc = ""]
                #[doc = " This is only used for validating equivocation proofs. An equivocation proof must"]
                #[doc = " contains a key-ownership proof for a given session, therefore we need a way to tie"]
                #[doc = " together sessions and GRANDPA set ids, i.e. we need to validate that a validator"]
                #[doc = " was the owner of a given key on a given session, and what the active set ID was"]
                #[doc = " during that session."]
                #[doc = ""]
                #[doc = " TWOX-NOTE: `SetId` is not under user control."]
                pub fn set_id_session(
                    &self,
                    _0: impl ::std::borrow::Borrow<types::set_id_session::Param0>,
                ) -> ::subxt::storage::address::Address<
                    ::subxt::storage::address::StaticStorageKey<types::set_id_session::Param0>,
                    types::set_id_session::SetIdSession,
                    ::subxt::storage::address::Yes,
                    (),
                    (),
                > {
                    ::subxt::storage::address::Address::new_static(
                        "Grandpa",
                        "SetIdSession",
                        ::subxt::storage::address::StaticStorageKey::new(_0.borrow()),
                        [
                            47u8, 0u8, 239u8, 121u8, 187u8, 213u8, 254u8, 50u8, 238u8, 10u8, 162u8, 65u8, 189u8, 166u8,
                            37u8, 74u8, 82u8, 81u8, 160u8, 20u8, 180u8, 253u8, 238u8, 18u8, 209u8, 203u8, 38u8, 148u8,
                            16u8, 105u8, 72u8, 169u8,
                        ],
                    )
                }
            }
        }
        pub mod constants {
            use super::runtime_types;
            pub struct ConstantsApi;
            impl ConstantsApi {
                #[doc = " Max Authorities in use"]
                pub fn max_authorities(&self) -> ::subxt::constants::Address<::core::primitive::u32> {
                    ::subxt::constants::Address::new_static(
                        "Grandpa",
                        "MaxAuthorities",
                        [
                            98u8, 252u8, 116u8, 72u8, 26u8, 180u8, 225u8, 83u8, 200u8, 157u8, 125u8, 151u8, 53u8, 76u8,
                            168u8, 26u8, 10u8, 9u8, 98u8, 68u8, 9u8, 178u8, 197u8, 113u8, 31u8, 79u8, 200u8, 90u8,
                            203u8, 100u8, 41u8, 145u8,
                        ],
                    )
                }
                #[doc = " The maximum number of nominators for each validator."]
                pub fn max_nominators(&self) -> ::subxt::constants::Address<::core::primitive::u32> {
                    ::subxt::constants::Address::new_static(
                        "Grandpa",
                        "MaxNominators",
                        [
                            98u8, 252u8, 116u8, 72u8, 26u8, 180u8, 225u8, 83u8, 200u8, 157u8, 125u8, 151u8, 53u8, 76u8,
                            168u8, 26u8, 10u8, 9u8, 98u8, 68u8, 9u8, 178u8, 197u8, 113u8, 31u8, 79u8, 200u8, 90u8,
                            203u8, 100u8, 41u8, 145u8,
                        ],
                    )
                }
                #[doc = " The maximum number of entries to keep in the set id to session index mapping."]
                #[doc = ""]
                #[doc = " Since the `SetIdSession` map is only used for validating equivocations this"]
                #[doc = " value should relate to the bonding duration of whatever staking system is"]
                #[doc = " being used (if any). If equivocation handling is not enabled then this value"]
                #[doc = " can be zero."]
                pub fn max_set_id_session_entries(&self) -> ::subxt::constants::Address<::core::primitive::u64> {
                    ::subxt::constants::Address::new_static(
                        "Grandpa",
                        "MaxSetIdSessionEntries",
                        [
                            128u8, 214u8, 205u8, 242u8, 181u8, 142u8, 124u8, 231u8, 190u8, 146u8, 59u8, 226u8, 157u8,
                            101u8, 103u8, 117u8, 249u8, 65u8, 18u8, 191u8, 103u8, 119u8, 53u8, 85u8, 81u8, 96u8, 220u8,
                            42u8, 184u8, 239u8, 42u8, 246u8,
                        ],
                    )
                }
            }
        }
    }
    pub mod starknet {
        use super::root_mod;
        use super::runtime_types;
        #[doc = "The Starknet pallet custom errors."]
        #[doc = "ERRORS"]
        pub type Error = runtime_types::pallet_starknet::pallet::Error;
        #[doc = "The Starknet pallet external functions."]
        #[doc = "Dispatchable functions allows users to interact with the pallet and invoke state changes."]
        #[doc = "These functions materialize as \"extrinsics\", which are often compared to transactions."]
        #[doc = "Dispatchable functions must be annotated with a weight and must return a DispatchResult."]
        pub type Call = runtime_types::pallet_starknet::pallet::Call;
        pub mod calls {
            use super::root_mod;
            use super::runtime_types;
            type DispatchError = runtime_types::sp_runtime::DispatchError;
            pub mod types {
                use super::runtime_types;
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                #[doc = "See [`Pallet::set_sequencer_address`]."]
                pub struct SetSequencerAddress {
                    pub addr: set_sequencer_address::Addr,
                }
                pub mod set_sequencer_address {
                    use super::runtime_types;
                    pub type Addr = [::core::primitive::u8; 32usize];
                }
                impl ::subxt::blocks::StaticExtrinsic for SetSequencerAddress {
                    const PALLET: &'static str = "Starknet";
                    const CALL: &'static str = "set_sequencer_address";
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                #[doc = "See [`Pallet::invoke`]."]
                pub struct Invoke {
                    pub transaction: invoke::Transaction,
                }
                pub mod invoke {
                    use super::runtime_types;
                    pub type Transaction = runtime_types::mp_transactions::InvokeTransaction;
                }
                impl ::subxt::blocks::StaticExtrinsic for Invoke {
                    const PALLET: &'static str = "Starknet";
                    const CALL: &'static str = "invoke";
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                #[doc = "See [`Pallet::declare`]."]
                pub struct Declare {
                    pub transaction: declare::Transaction,
                    pub contract_class: declare::ContractClass,
                }
                pub mod declare {
                    use super::runtime_types;
                    pub type Transaction = runtime_types::mp_transactions::DeclareTransaction;
                    pub type ContractClass = runtime_types::blockifier::execution::contract_class::ContractClass;
                }
                impl ::subxt::blocks::StaticExtrinsic for Declare {
                    const PALLET: &'static str = "Starknet";
                    const CALL: &'static str = "declare";
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                #[doc = "See [`Pallet::deploy_account`]."]
                pub struct DeployAccount {
                    pub transaction: deploy_account::Transaction,
                }
                pub mod deploy_account {
                    use super::runtime_types;
                    pub type Transaction = runtime_types::mp_transactions::DeployAccountTransaction;
                }
                impl ::subxt::blocks::StaticExtrinsic for DeployAccount {
                    const PALLET: &'static str = "Starknet";
                    const CALL: &'static str = "deploy_account";
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                #[doc = "See [`Pallet::consume_l1_message`]."]
                pub struct ConsumeL1Message {
                    pub transaction: consume_l1_message::Transaction,
                    pub paid_fee_on_l1: consume_l1_message::PaidFeeOnL1,
                }
                pub mod consume_l1_message {
                    use super::runtime_types;
                    pub type Transaction = runtime_types::mp_transactions::HandleL1MessageTransaction;
                    pub type PaidFeeOnL1 = runtime_types::starknet_api::transaction::Fee;
                }
                impl ::subxt::blocks::StaticExtrinsic for ConsumeL1Message {
                    const PALLET: &'static str = "Starknet";
                    const CALL: &'static str = "consume_l1_message";
                }
            }
            pub struct TransactionApi;
            impl TransactionApi {
                #[doc = "See [`Pallet::set_sequencer_address`]."]
                pub fn set_sequencer_address(
                    &self,
                    addr: types::set_sequencer_address::Addr,
                ) -> ::subxt::tx::Payload<types::SetSequencerAddress> {
                    ::subxt::tx::Payload::new_static(
                        "Starknet",
                        "set_sequencer_address",
                        types::SetSequencerAddress { addr },
                        [
                            169u8, 26u8, 33u8, 250u8, 166u8, 134u8, 232u8, 133u8, 55u8, 175u8, 66u8, 239u8, 41u8,
                            169u8, 98u8, 174u8, 140u8, 37u8, 219u8, 244u8, 241u8, 223u8, 217u8, 81u8, 149u8, 123u8,
                            195u8, 228u8, 103u8, 201u8, 113u8, 94u8,
                        ],
                    )
                }
                #[doc = "See [`Pallet::invoke`]."]
                pub fn invoke(&self, transaction: types::invoke::Transaction) -> ::subxt::tx::Payload<types::Invoke> {
                    ::subxt::tx::Payload::new_static(
                        "Starknet",
                        "invoke",
                        types::Invoke { transaction },
                        [
                            85u8, 17u8, 2u8, 235u8, 36u8, 132u8, 208u8, 46u8, 163u8, 207u8, 213u8, 244u8, 110u8, 92u8,
                            166u8, 212u8, 59u8, 93u8, 234u8, 176u8, 75u8, 134u8, 172u8, 162u8, 64u8, 253u8, 136u8,
                            29u8, 107u8, 128u8, 57u8, 153u8,
                        ],
                    )
                }
                #[doc = "See [`Pallet::declare`]."]
                pub fn declare(
                    &self,
                    transaction: types::declare::Transaction,
                    contract_class: types::declare::ContractClass,
                ) -> ::subxt::tx::Payload<types::Declare> {
                    ::subxt::tx::Payload::new_static(
                        "Starknet",
                        "declare",
                        types::Declare { transaction, contract_class },
                        [
                            51u8, 168u8, 26u8, 92u8, 124u8, 211u8, 249u8, 222u8, 97u8, 183u8, 74u8, 98u8, 198u8, 228u8,
                            105u8, 222u8, 18u8, 138u8, 61u8, 48u8, 47u8, 228u8, 152u8, 205u8, 226u8, 55u8, 212u8,
                            206u8, 122u8, 51u8, 201u8, 110u8,
                        ],
                    )
                }
                #[doc = "See [`Pallet::deploy_account`]."]
                pub fn deploy_account(
                    &self,
                    transaction: types::deploy_account::Transaction,
                ) -> ::subxt::tx::Payload<types::DeployAccount> {
                    ::subxt::tx::Payload::new_static(
                        "Starknet",
                        "deploy_account",
                        types::DeployAccount { transaction },
                        [
                            83u8, 35u8, 190u8, 103u8, 87u8, 56u8, 43u8, 218u8, 33u8, 76u8, 114u8, 250u8, 228u8, 8u8,
                            220u8, 189u8, 165u8, 197u8, 106u8, 131u8, 232u8, 15u8, 215u8, 178u8, 174u8, 235u8, 239u8,
                            201u8, 162u8, 43u8, 175u8, 99u8,
                        ],
                    )
                }
                #[doc = "See [`Pallet::consume_l1_message`]."]
                pub fn consume_l1_message(
                    &self,
                    transaction: types::consume_l1_message::Transaction,
                    paid_fee_on_l1: types::consume_l1_message::PaidFeeOnL1,
                ) -> ::subxt::tx::Payload<types::ConsumeL1Message> {
                    ::subxt::tx::Payload::new_static(
                        "Starknet",
                        "consume_l1_message",
                        types::ConsumeL1Message { transaction, paid_fee_on_l1 },
                        [
                            163u8, 125u8, 67u8, 173u8, 100u8, 72u8, 223u8, 26u8, 56u8, 92u8, 169u8, 125u8, 58u8, 205u8,
                            189u8, 68u8, 24u8, 158u8, 149u8, 26u8, 42u8, 81u8, 79u8, 16u8, 177u8, 200u8, 189u8, 224u8,
                            44u8, 118u8, 0u8, 233u8,
                        ],
                    )
                }
            }
        }
        pub mod storage {
            use super::runtime_types;
            pub mod types {
                use super::runtime_types;
                pub mod pending {
                    use super::runtime_types;
                    pub type Pending = ::std::vec::Vec<runtime_types::mp_transactions::Transaction>;
                }
                pub mod pending_hashes {
                    use super::runtime_types;
                    pub type PendingHashes = ::std::vec::Vec<runtime_types::starknet_api::transaction::TransactionHash>;
                }
                pub mod tx_events {
                    use super::runtime_types;
                    pub type TxEvents = ::std::vec::Vec<runtime_types::starknet_api::transaction::Event>;
                    pub type Param0 = runtime_types::starknet_api::transaction::TransactionHash;
                }
                pub mod tx_messages {
                    use super::runtime_types;
                    pub type TxMessages = ::std::vec::Vec<runtime_types::starknet_api::transaction::MessageToL1>;
                    pub type Param0 = runtime_types::starknet_api::transaction::TransactionHash;
                }
                pub mod tx_revert_error {
                    use super::runtime_types;
                    pub type TxRevertError = ::std::string::String;
                    pub type Param0 = runtime_types::starknet_api::transaction::TransactionHash;
                }
                pub mod contracts_state_roots {
                    use super::runtime_types;
                    pub type ContractsStateRoots = runtime_types::mp_felt::Felt252Wrapper;
                    pub type Param0 = runtime_types::starknet_api::api_core::ContractAddress;
                }
                pub mod pending_storage_changes {
                    use super::runtime_types;
                    pub type PendingStorageChanges = ::std::vec::Vec<(
                        runtime_types::starknet_api::state::StorageKey,
                        runtime_types::mp_felt::Felt252Wrapper,
                    )>;
                    pub type Param0 = runtime_types::starknet_api::api_core::ContractAddress;
                }
                pub mod block_hash {
                    use super::runtime_types;
                    pub type BlockHash = runtime_types::mp_felt::Felt252Wrapper;
                    pub type Param0 = ::core::primitive::u64;
                }
                pub mod contract_class_hashes {
                    use super::runtime_types;
                    pub type ContractClassHashes = runtime_types::starknet_api::api_core::ClassHash;
                    pub type Param0 = runtime_types::starknet_api::api_core::ContractAddress;
                }
                pub mod contract_classes {
                    use super::runtime_types;
                    pub type ContractClasses = runtime_types::blockifier::execution::contract_class::ContractClass;
                    pub type Param0 = runtime_types::starknet_api::api_core::ClassHash;
                }
                pub mod compiled_class_hashes {
                    use super::runtime_types;
                    pub type CompiledClassHashes = runtime_types::starknet_api::api_core::CompiledClassHash;
                    pub type Param0 = runtime_types::starknet_api::api_core::ClassHash;
                }
                pub mod nonces {
                    use super::runtime_types;
                    pub type Nonces = runtime_types::starknet_api::api_core::Nonce;
                    pub type Param0 = runtime_types::starknet_api::api_core::ContractAddress;
                }
                pub mod storage_view {
                    use super::runtime_types;
                    pub type StorageView = runtime_types::starknet_api::hash::StarkFelt;
                    pub type Param0 = runtime_types::starknet_api::api_core::ContractAddress;
                    pub type Param1 = runtime_types::starknet_api::state::StorageKey;
                }
                pub mod last_known_eth_block {
                    use super::runtime_types;
                    pub type LastKnownEthBlock = ::core::primitive::u64;
                }
                pub mod fee_token_address {
                    use super::runtime_types;
                    pub type FeeTokenAddress = runtime_types::starknet_api::api_core::ContractAddress;
                }
                pub mod sequencer_address {
                    use super::runtime_types;
                    pub type SequencerAddress = runtime_types::starknet_api::api_core::ContractAddress;
                }
                pub mod seq_addr_update {
                    use super::runtime_types;
                    pub type SeqAddrUpdate = ::core::primitive::bool;
                }
                pub mod l1_messages {
                    use super::runtime_types;
                    pub type L1Messages = ::std::vec::Vec<runtime_types::starknet_api::api_core::Nonce>;
                }
            }
            pub struct StorageApi;
            impl StorageApi {
                #[doc = " The Starknet pallet storage items."]
                #[doc = " STORAGE"]
                #[doc = " Current building block's transactions."]
                pub fn pending(
                    &self,
                ) -> ::subxt::storage::address::Address<
                    (),
                    types::pending::Pending,
                    ::subxt::storage::address::Yes,
                    ::subxt::storage::address::Yes,
                    (),
                > {
                    ::subxt::storage::address::Address::new_static(
                        "Starknet",
                        "Pending",
                        (),
                        [
                            84u8, 54u8, 119u8, 230u8, 72u8, 65u8, 155u8, 131u8, 53u8, 149u8, 140u8, 155u8, 24u8, 140u8,
                            246u8, 87u8, 214u8, 136u8, 158u8, 39u8, 221u8, 39u8, 245u8, 53u8, 3u8, 36u8, 9u8, 178u8,
                            17u8, 50u8, 126u8, 60u8,
                        ],
                    )
                }
                pub fn pending_hashes(
                    &self,
                ) -> ::subxt::storage::address::Address<
                    (),
                    types::pending_hashes::PendingHashes,
                    ::subxt::storage::address::Yes,
                    ::subxt::storage::address::Yes,
                    (),
                > {
                    ::subxt::storage::address::Address::new_static(
                        "Starknet",
                        "PendingHashes",
                        (),
                        [
                            66u8, 137u8, 130u8, 57u8, 29u8, 64u8, 57u8, 214u8, 150u8, 219u8, 146u8, 144u8, 151u8,
                            215u8, 0u8, 55u8, 199u8, 44u8, 55u8, 64u8, 31u8, 113u8, 27u8, 86u8, 210u8, 4u8, 188u8,
                            184u8, 217u8, 161u8, 76u8, 123u8,
                        ],
                    )
                }
                pub fn tx_events_iter(
                    &self,
                ) -> ::subxt::storage::address::Address<
                    (),
                    types::tx_events::TxEvents,
                    (),
                    ::subxt::storage::address::Yes,
                    ::subxt::storage::address::Yes,
                > {
                    ::subxt::storage::address::Address::new_static(
                        "Starknet",
                        "TxEvents",
                        (),
                        [
                            121u8, 221u8, 127u8, 211u8, 86u8, 203u8, 128u8, 198u8, 221u8, 89u8, 110u8, 99u8, 184u8,
                            167u8, 140u8, 177u8, 171u8, 25u8, 236u8, 201u8, 94u8, 6u8, 73u8, 35u8, 221u8, 204u8, 221u8,
                            187u8, 247u8, 251u8, 173u8, 14u8,
                        ],
                    )
                }
                pub fn tx_events(
                    &self,
                    _0: impl ::std::borrow::Borrow<types::tx_events::Param0>,
                ) -> ::subxt::storage::address::Address<
                    ::subxt::storage::address::StaticStorageKey<types::tx_events::Param0>,
                    types::tx_events::TxEvents,
                    ::subxt::storage::address::Yes,
                    ::subxt::storage::address::Yes,
                    (),
                > {
                    ::subxt::storage::address::Address::new_static(
                        "Starknet",
                        "TxEvents",
                        ::subxt::storage::address::StaticStorageKey::new(_0.borrow()),
                        [
                            121u8, 221u8, 127u8, 211u8, 86u8, 203u8, 128u8, 198u8, 221u8, 89u8, 110u8, 99u8, 184u8,
                            167u8, 140u8, 177u8, 171u8, 25u8, 236u8, 201u8, 94u8, 6u8, 73u8, 35u8, 221u8, 204u8, 221u8,
                            187u8, 247u8, 251u8, 173u8, 14u8,
                        ],
                    )
                }
                pub fn tx_messages_iter(
                    &self,
                ) -> ::subxt::storage::address::Address<
                    (),
                    types::tx_messages::TxMessages,
                    (),
                    ::subxt::storage::address::Yes,
                    ::subxt::storage::address::Yes,
                > {
                    ::subxt::storage::address::Address::new_static(
                        "Starknet",
                        "TxMessages",
                        (),
                        [
                            167u8, 160u8, 91u8, 132u8, 79u8, 241u8, 107u8, 41u8, 163u8, 195u8, 225u8, 232u8, 145u8,
                            217u8, 48u8, 98u8, 150u8, 247u8, 235u8, 102u8, 151u8, 238u8, 11u8, 107u8, 241u8, 54u8,
                            137u8, 234u8, 168u8, 14u8, 73u8, 227u8,
                        ],
                    )
                }
                pub fn tx_messages(
                    &self,
                    _0: impl ::std::borrow::Borrow<types::tx_messages::Param0>,
                ) -> ::subxt::storage::address::Address<
                    ::subxt::storage::address::StaticStorageKey<types::tx_messages::Param0>,
                    types::tx_messages::TxMessages,
                    ::subxt::storage::address::Yes,
                    ::subxt::storage::address::Yes,
                    (),
                > {
                    ::subxt::storage::address::Address::new_static(
                        "Starknet",
                        "TxMessages",
                        ::subxt::storage::address::StaticStorageKey::new(_0.borrow()),
                        [
                            167u8, 160u8, 91u8, 132u8, 79u8, 241u8, 107u8, 41u8, 163u8, 195u8, 225u8, 232u8, 145u8,
                            217u8, 48u8, 98u8, 150u8, 247u8, 235u8, 102u8, 151u8, 238u8, 11u8, 107u8, 241u8, 54u8,
                            137u8, 234u8, 168u8, 14u8, 73u8, 227u8,
                        ],
                    )
                }
                pub fn tx_revert_error_iter(
                    &self,
                ) -> ::subxt::storage::address::Address<
                    (),
                    types::tx_revert_error::TxRevertError,
                    (),
                    (),
                    ::subxt::storage::address::Yes,
                > {
                    ::subxt::storage::address::Address::new_static(
                        "Starknet",
                        "TxRevertError",
                        (),
                        [
                            135u8, 202u8, 162u8, 217u8, 245u8, 163u8, 157u8, 219u8, 170u8, 92u8, 64u8, 59u8, 204u8,
                            168u8, 146u8, 93u8, 221u8, 30u8, 79u8, 181u8, 70u8, 49u8, 136u8, 164u8, 1u8, 234u8, 28u8,
                            13u8, 222u8, 32u8, 237u8, 60u8,
                        ],
                    )
                }
                pub fn tx_revert_error(
                    &self,
                    _0: impl ::std::borrow::Borrow<types::tx_revert_error::Param0>,
                ) -> ::subxt::storage::address::Address<
                    ::subxt::storage::address::StaticStorageKey<types::tx_revert_error::Param0>,
                    types::tx_revert_error::TxRevertError,
                    ::subxt::storage::address::Yes,
                    (),
                    (),
                > {
                    ::subxt::storage::address::Address::new_static(
                        "Starknet",
                        "TxRevertError",
                        ::subxt::storage::address::StaticStorageKey::new(_0.borrow()),
                        [
                            135u8, 202u8, 162u8, 217u8, 245u8, 163u8, 157u8, 219u8, 170u8, 92u8, 64u8, 59u8, 204u8,
                            168u8, 146u8, 93u8, 221u8, 30u8, 79u8, 181u8, 70u8, 49u8, 136u8, 164u8, 1u8, 234u8, 28u8,
                            13u8, 222u8, 32u8, 237u8, 60u8,
                        ],
                    )
                }
                #[doc = " The Starknet pallet storage items."]
                #[doc = " STORAGE"]
                #[doc = " Mapping of contract address to state root."]
                pub fn contracts_state_roots_iter(
                    &self,
                ) -> ::subxt::storage::address::Address<
                    (),
                    types::contracts_state_roots::ContractsStateRoots,
                    (),
                    (),
                    ::subxt::storage::address::Yes,
                > {
                    ::subxt::storage::address::Address::new_static(
                        "Starknet",
                        "ContractsStateRoots",
                        (),
                        [
                            229u8, 249u8, 42u8, 22u8, 180u8, 204u8, 109u8, 58u8, 8u8, 151u8, 244u8, 138u8, 112u8,
                            214u8, 87u8, 191u8, 95u8, 114u8, 61u8, 127u8, 210u8, 88u8, 229u8, 154u8, 33u8, 62u8, 108u8,
                            153u8, 150u8, 109u8, 103u8, 59u8,
                        ],
                    )
                }
                #[doc = " The Starknet pallet storage items."]
                #[doc = " STORAGE"]
                #[doc = " Mapping of contract address to state root."]
                pub fn contracts_state_roots(
                    &self,
                    _0: impl ::std::borrow::Borrow<types::contracts_state_roots::Param0>,
                ) -> ::subxt::storage::address::Address<
                    ::subxt::storage::address::StaticStorageKey<types::contracts_state_roots::Param0>,
                    types::contracts_state_roots::ContractsStateRoots,
                    ::subxt::storage::address::Yes,
                    (),
                    (),
                > {
                    ::subxt::storage::address::Address::new_static(
                        "Starknet",
                        "ContractsStateRoots",
                        ::subxt::storage::address::StaticStorageKey::new(_0.borrow()),
                        [
                            229u8, 249u8, 42u8, 22u8, 180u8, 204u8, 109u8, 58u8, 8u8, 151u8, 244u8, 138u8, 112u8,
                            214u8, 87u8, 191u8, 95u8, 114u8, 61u8, 127u8, 210u8, 88u8, 229u8, 154u8, 33u8, 62u8, 108u8,
                            153u8, 150u8, 109u8, 103u8, 59u8,
                        ],
                    )
                }
                #[doc = " Pending storage slot updates"]
                #[doc = " STORAGE"]
                #[doc = " Mapping storage key to storage value."]
                pub fn pending_storage_changes_iter(
                    &self,
                ) -> ::subxt::storage::address::Address<
                    (),
                    types::pending_storage_changes::PendingStorageChanges,
                    (),
                    ::subxt::storage::address::Yes,
                    ::subxt::storage::address::Yes,
                > {
                    ::subxt::storage::address::Address::new_static(
                        "Starknet",
                        "PendingStorageChanges",
                        (),
                        [
                            164u8, 119u8, 210u8, 206u8, 60u8, 14u8, 39u8, 11u8, 109u8, 110u8, 175u8, 105u8, 56u8,
                            188u8, 73u8, 130u8, 180u8, 56u8, 78u8, 81u8, 108u8, 255u8, 109u8, 246u8, 244u8, 20u8,
                            157u8, 59u8, 134u8, 213u8, 167u8, 84u8,
                        ],
                    )
                }
                #[doc = " Pending storage slot updates"]
                #[doc = " STORAGE"]
                #[doc = " Mapping storage key to storage value."]
                pub fn pending_storage_changes(
                    &self,
                    _0: impl ::std::borrow::Borrow<types::pending_storage_changes::Param0>,
                ) -> ::subxt::storage::address::Address<
                    ::subxt::storage::address::StaticStorageKey<types::pending_storage_changes::Param0>,
                    types::pending_storage_changes::PendingStorageChanges,
                    ::subxt::storage::address::Yes,
                    ::subxt::storage::address::Yes,
                    (),
                > {
                    ::subxt::storage::address::Address::new_static(
                        "Starknet",
                        "PendingStorageChanges",
                        ::subxt::storage::address::StaticStorageKey::new(_0.borrow()),
                        [
                            164u8, 119u8, 210u8, 206u8, 60u8, 14u8, 39u8, 11u8, 109u8, 110u8, 175u8, 105u8, 56u8,
                            188u8, 73u8, 130u8, 180u8, 56u8, 78u8, 81u8, 108u8, 255u8, 109u8, 246u8, 244u8, 20u8,
                            157u8, 59u8, 134u8, 213u8, 167u8, 84u8,
                        ],
                    )
                }
                #[doc = " Mapping for block number and hashes."]
                #[doc = " Safe to use `Identity` as the key is already a hash."]
                pub fn block_hash_iter(
                    &self,
                ) -> ::subxt::storage::address::Address<
                    (),
                    types::block_hash::BlockHash,
                    (),
                    ::subxt::storage::address::Yes,
                    ::subxt::storage::address::Yes,
                > {
                    ::subxt::storage::address::Address::new_static(
                        "Starknet",
                        "BlockHash",
                        (),
                        [
                            136u8, 185u8, 29u8, 194u8, 72u8, 62u8, 93u8, 202u8, 59u8, 231u8, 199u8, 32u8, 71u8, 128u8,
                            203u8, 237u8, 92u8, 50u8, 122u8, 167u8, 75u8, 26u8, 233u8, 203u8, 104u8, 139u8, 215u8,
                            149u8, 55u8, 218u8, 50u8, 113u8,
                        ],
                    )
                }
                #[doc = " Mapping for block number and hashes."]
                #[doc = " Safe to use `Identity` as the key is already a hash."]
                pub fn block_hash(
                    &self,
                    _0: impl ::std::borrow::Borrow<types::block_hash::Param0>,
                ) -> ::subxt::storage::address::Address<
                    ::subxt::storage::address::StaticStorageKey<types::block_hash::Param0>,
                    types::block_hash::BlockHash,
                    ::subxt::storage::address::Yes,
                    ::subxt::storage::address::Yes,
                    (),
                > {
                    ::subxt::storage::address::Address::new_static(
                        "Starknet",
                        "BlockHash",
                        ::subxt::storage::address::StaticStorageKey::new(_0.borrow()),
                        [
                            136u8, 185u8, 29u8, 194u8, 72u8, 62u8, 93u8, 202u8, 59u8, 231u8, 199u8, 32u8, 71u8, 128u8,
                            203u8, 237u8, 92u8, 50u8, 122u8, 167u8, 75u8, 26u8, 233u8, 203u8, 104u8, 139u8, 215u8,
                            149u8, 55u8, 218u8, 50u8, 113u8,
                        ],
                    )
                }
                #[doc = " Mapping from Starknet contract address to the contract's class hash."]
                #[doc = " Safe to use `Identity` as the key is already a hash."]
                pub fn contract_class_hashes_iter(
                    &self,
                ) -> ::subxt::storage::address::Address<
                    (),
                    types::contract_class_hashes::ContractClassHashes,
                    (),
                    ::subxt::storage::address::Yes,
                    ::subxt::storage::address::Yes,
                > {
                    ::subxt::storage::address::Address::new_static(
                        "Starknet",
                        "ContractClassHashes",
                        (),
                        [
                            134u8, 45u8, 113u8, 42u8, 146u8, 136u8, 240u8, 221u8, 0u8, 154u8, 218u8, 167u8, 114u8,
                            119u8, 133u8, 137u8, 235u8, 201u8, 135u8, 204u8, 174u8, 33u8, 130u8, 230u8, 244u8, 87u8,
                            47u8, 164u8, 221u8, 71u8, 71u8, 138u8,
                        ],
                    )
                }
                #[doc = " Mapping from Starknet contract address to the contract's class hash."]
                #[doc = " Safe to use `Identity` as the key is already a hash."]
                pub fn contract_class_hashes(
                    &self,
                    _0: impl ::std::borrow::Borrow<types::contract_class_hashes::Param0>,
                ) -> ::subxt::storage::address::Address<
                    ::subxt::storage::address::StaticStorageKey<types::contract_class_hashes::Param0>,
                    types::contract_class_hashes::ContractClassHashes,
                    ::subxt::storage::address::Yes,
                    ::subxt::storage::address::Yes,
                    (),
                > {
                    ::subxt::storage::address::Address::new_static(
                        "Starknet",
                        "ContractClassHashes",
                        ::subxt::storage::address::StaticStorageKey::new(_0.borrow()),
                        [
                            134u8, 45u8, 113u8, 42u8, 146u8, 136u8, 240u8, 221u8, 0u8, 154u8, 218u8, 167u8, 114u8,
                            119u8, 133u8, 137u8, 235u8, 201u8, 135u8, 204u8, 174u8, 33u8, 130u8, 230u8, 244u8, 87u8,
                            47u8, 164u8, 221u8, 71u8, 71u8, 138u8,
                        ],
                    )
                }
                #[doc = " Mapping from Starknet class hash to contract class."]
                #[doc = " Safe to use `Identity` as the key is already a hash."]
                pub fn contract_classes_iter(
                    &self,
                ) -> ::subxt::storage::address::Address<
                    (),
                    types::contract_classes::ContractClasses,
                    (),
                    (),
                    ::subxt::storage::address::Yes,
                > {
                    ::subxt::storage::address::Address::new_static(
                        "Starknet",
                        "ContractClasses",
                        (),
                        [
                            249u8, 24u8, 108u8, 51u8, 136u8, 97u8, 170u8, 65u8, 255u8, 44u8, 91u8, 209u8, 79u8, 189u8,
                            207u8, 200u8, 79u8, 5u8, 41u8, 9u8, 221u8, 220u8, 214u8, 145u8, 244u8, 158u8, 28u8, 182u8,
                            223u8, 7u8, 244u8, 102u8,
                        ],
                    )
                }
                #[doc = " Mapping from Starknet class hash to contract class."]
                #[doc = " Safe to use `Identity` as the key is already a hash."]
                pub fn contract_classes(
                    &self,
                    _0: impl ::std::borrow::Borrow<types::contract_classes::Param0>,
                ) -> ::subxt::storage::address::Address<
                    ::subxt::storage::address::StaticStorageKey<types::contract_classes::Param0>,
                    types::contract_classes::ContractClasses,
                    ::subxt::storage::address::Yes,
                    (),
                    (),
                > {
                    ::subxt::storage::address::Address::new_static(
                        "Starknet",
                        "ContractClasses",
                        ::subxt::storage::address::StaticStorageKey::new(_0.borrow()),
                        [
                            249u8, 24u8, 108u8, 51u8, 136u8, 97u8, 170u8, 65u8, 255u8, 44u8, 91u8, 209u8, 79u8, 189u8,
                            207u8, 200u8, 79u8, 5u8, 41u8, 9u8, 221u8, 220u8, 214u8, 145u8, 244u8, 158u8, 28u8, 182u8,
                            223u8, 7u8, 244u8, 102u8,
                        ],
                    )
                }
                #[doc = " Mapping from Starknet Sierra class hash to  Casm compiled contract class."]
                #[doc = " Safe to use `Identity` as the key is already a hash."]
                pub fn compiled_class_hashes_iter(
                    &self,
                ) -> ::subxt::storage::address::Address<
                    (),
                    types::compiled_class_hashes::CompiledClassHashes,
                    (),
                    (),
                    ::subxt::storage::address::Yes,
                > {
                    ::subxt::storage::address::Address::new_static(
                        "Starknet",
                        "CompiledClassHashes",
                        (),
                        [
                            16u8, 255u8, 109u8, 187u8, 48u8, 225u8, 113u8, 26u8, 67u8, 134u8, 61u8, 248u8, 246u8,
                            231u8, 191u8, 29u8, 140u8, 141u8, 55u8, 147u8, 127u8, 133u8, 130u8, 137u8, 189u8, 33u8,
                            187u8, 109u8, 45u8, 67u8, 101u8, 73u8,
                        ],
                    )
                }
                #[doc = " Mapping from Starknet Sierra class hash to  Casm compiled contract class."]
                #[doc = " Safe to use `Identity` as the key is already a hash."]
                pub fn compiled_class_hashes(
                    &self,
                    _0: impl ::std::borrow::Borrow<types::compiled_class_hashes::Param0>,
                ) -> ::subxt::storage::address::Address<
                    ::subxt::storage::address::StaticStorageKey<types::compiled_class_hashes::Param0>,
                    types::compiled_class_hashes::CompiledClassHashes,
                    ::subxt::storage::address::Yes,
                    (),
                    (),
                > {
                    ::subxt::storage::address::Address::new_static(
                        "Starknet",
                        "CompiledClassHashes",
                        ::subxt::storage::address::StaticStorageKey::new(_0.borrow()),
                        [
                            16u8, 255u8, 109u8, 187u8, 48u8, 225u8, 113u8, 26u8, 67u8, 134u8, 61u8, 248u8, 246u8,
                            231u8, 191u8, 29u8, 140u8, 141u8, 55u8, 147u8, 127u8, 133u8, 130u8, 137u8, 189u8, 33u8,
                            187u8, 109u8, 45u8, 67u8, 101u8, 73u8,
                        ],
                    )
                }
                #[doc = " Mapping from Starknet contract address to its nonce."]
                #[doc = " Safe to use `Identity` as the key is already a hash."]
                pub fn nonces_iter(
                    &self,
                ) -> ::subxt::storage::address::Address<
                    (),
                    types::nonces::Nonces,
                    (),
                    ::subxt::storage::address::Yes,
                    ::subxt::storage::address::Yes,
                > {
                    ::subxt::storage::address::Address::new_static(
                        "Starknet",
                        "Nonces",
                        (),
                        [
                            235u8, 122u8, 110u8, 231u8, 171u8, 151u8, 159u8, 224u8, 190u8, 13u8, 0u8, 106u8, 250u8,
                            25u8, 89u8, 242u8, 164u8, 98u8, 63u8, 56u8, 181u8, 34u8, 0u8, 155u8, 112u8, 144u8, 75u8,
                            239u8, 21u8, 137u8, 225u8, 232u8,
                        ],
                    )
                }
                #[doc = " Mapping from Starknet contract address to its nonce."]
                #[doc = " Safe to use `Identity` as the key is already a hash."]
                pub fn nonces(
                    &self,
                    _0: impl ::std::borrow::Borrow<types::nonces::Param0>,
                ) -> ::subxt::storage::address::Address<
                    ::subxt::storage::address::StaticStorageKey<types::nonces::Param0>,
                    types::nonces::Nonces,
                    ::subxt::storage::address::Yes,
                    ::subxt::storage::address::Yes,
                    (),
                > {
                    ::subxt::storage::address::Address::new_static(
                        "Starknet",
                        "Nonces",
                        ::subxt::storage::address::StaticStorageKey::new(_0.borrow()),
                        [
                            235u8, 122u8, 110u8, 231u8, 171u8, 151u8, 159u8, 224u8, 190u8, 13u8, 0u8, 106u8, 250u8,
                            25u8, 89u8, 242u8, 164u8, 98u8, 63u8, 56u8, 181u8, 34u8, 0u8, 155u8, 112u8, 144u8, 75u8,
                            239u8, 21u8, 137u8, 225u8, 232u8,
                        ],
                    )
                }
                #[doc = " Mapping from Starknet contract storage key to its value."]
                #[doc = " Safe to use `Identity` as the key is already a hash."]
                pub fn storage_view_iter(
                    &self,
                ) -> ::subxt::storage::address::Address<
                    (),
                    types::storage_view::StorageView,
                    (),
                    ::subxt::storage::address::Yes,
                    ::subxt::storage::address::Yes,
                > {
                    ::subxt::storage::address::Address::new_static(
                        "Starknet",
                        "StorageView",
                        (),
                        [
                            167u8, 146u8, 218u8, 79u8, 41u8, 243u8, 153u8, 185u8, 246u8, 39u8, 34u8, 194u8, 2u8, 36u8,
                            122u8, 249u8, 16u8, 241u8, 86u8, 76u8, 190u8, 193u8, 234u8, 31u8, 219u8, 20u8, 109u8,
                            159u8, 24u8, 24u8, 236u8, 150u8,
                        ],
                    )
                }
                #[doc = " Mapping from Starknet contract storage key to its value."]
                #[doc = " Safe to use `Identity` as the key is already a hash."]
                pub fn storage_view_iter1(
                    &self,
                    _0: impl ::std::borrow::Borrow<types::storage_view::Param0>,
                ) -> ::subxt::storage::address::Address<
                    ::subxt::storage::address::StaticStorageKey<types::storage_view::Param0>,
                    types::storage_view::StorageView,
                    (),
                    ::subxt::storage::address::Yes,
                    ::subxt::storage::address::Yes,
                > {
                    ::subxt::storage::address::Address::new_static(
                        "Starknet",
                        "StorageView",
                        ::subxt::storage::address::StaticStorageKey::new(_0.borrow()),
                        [
                            167u8, 146u8, 218u8, 79u8, 41u8, 243u8, 153u8, 185u8, 246u8, 39u8, 34u8, 194u8, 2u8, 36u8,
                            122u8, 249u8, 16u8, 241u8, 86u8, 76u8, 190u8, 193u8, 234u8, 31u8, 219u8, 20u8, 109u8,
                            159u8, 24u8, 24u8, 236u8, 150u8,
                        ],
                    )
                }
                #[doc = " Mapping from Starknet contract storage key to its value."]
                #[doc = " Safe to use `Identity` as the key is already a hash."]
                pub fn storage_view(
                    &self,
                    _0: impl ::std::borrow::Borrow<types::storage_view::Param0>,
                    _1: impl ::std::borrow::Borrow<types::storage_view::Param1>,
                ) -> ::subxt::storage::address::Address<
                    (
                        ::subxt::storage::address::StaticStorageKey<types::storage_view::Param0>,
                        ::subxt::storage::address::StaticStorageKey<types::storage_view::Param1>,
                    ),
                    types::storage_view::StorageView,
                    ::subxt::storage::address::Yes,
                    ::subxt::storage::address::Yes,
                    (),
                > {
                    ::subxt::storage::address::Address::new_static(
                        "Starknet",
                        "StorageView",
                        (
                            ::subxt::storage::address::StaticStorageKey::new(_0.borrow()),
                            ::subxt::storage::address::StaticStorageKey::new(_1.borrow()),
                        ),
                        [
                            167u8, 146u8, 218u8, 79u8, 41u8, 243u8, 153u8, 185u8, 246u8, 39u8, 34u8, 194u8, 2u8, 36u8,
                            122u8, 249u8, 16u8, 241u8, 86u8, 76u8, 190u8, 193u8, 234u8, 31u8, 219u8, 20u8, 109u8,
                            159u8, 24u8, 24u8, 236u8, 150u8,
                        ],
                    )
                }
                #[doc = " The last processed Ethereum block number for L1 messages consumption."]
                #[doc = " This is used to avoid re-processing the same Ethereum block multiple times."]
                #[doc = " This is used by the offchain worker."]
                #[doc = " # TODO"]
                #[doc = " * Find a more relevant name for this."]
                pub fn last_known_eth_block(
                    &self,
                ) -> ::subxt::storage::address::Address<
                    (),
                    types::last_known_eth_block::LastKnownEthBlock,
                    ::subxt::storage::address::Yes,
                    (),
                    (),
                > {
                    ::subxt::storage::address::Address::new_static(
                        "Starknet",
                        "LastKnownEthBlock",
                        (),
                        [
                            166u8, 178u8, 57u8, 216u8, 0u8, 63u8, 226u8, 197u8, 145u8, 98u8, 38u8, 69u8, 113u8, 73u8,
                            223u8, 181u8, 230u8, 158u8, 206u8, 68u8, 147u8, 217u8, 203u8, 228u8, 171u8, 114u8, 237u8,
                            137u8, 100u8, 114u8, 94u8, 6u8,
                        ],
                    )
                }
                #[doc = " The address of the fee token ERC20 contract."]
                pub fn fee_token_address(
                    &self,
                ) -> ::subxt::storage::address::Address<
                    (),
                    types::fee_token_address::FeeTokenAddress,
                    ::subxt::storage::address::Yes,
                    ::subxt::storage::address::Yes,
                    (),
                > {
                    ::subxt::storage::address::Address::new_static(
                        "Starknet",
                        "FeeTokenAddress",
                        (),
                        [
                            189u8, 33u8, 185u8, 103u8, 164u8, 79u8, 96u8, 107u8, 253u8, 109u8, 193u8, 77u8, 130u8,
                            217u8, 61u8, 5u8, 155u8, 190u8, 216u8, 132u8, 55u8, 253u8, 98u8, 247u8, 211u8, 18u8, 93u8,
                            165u8, 218u8, 121u8, 79u8, 18u8,
                        ],
                    )
                }
                #[doc = " Current sequencer address."]
                pub fn sequencer_address(
                    &self,
                ) -> ::subxt::storage::address::Address<
                    (),
                    types::sequencer_address::SequencerAddress,
                    ::subxt::storage::address::Yes,
                    ::subxt::storage::address::Yes,
                    (),
                > {
                    ::subxt::storage::address::Address::new_static(
                        "Starknet",
                        "SequencerAddress",
                        (),
                        [
                            247u8, 120u8, 203u8, 213u8, 64u8, 34u8, 196u8, 214u8, 252u8, 242u8, 84u8, 7u8, 188u8, 8u8,
                            97u8, 163u8, 191u8, 219u8, 78u8, 238u8, 10u8, 201u8, 226u8, 95u8, 21u8, 35u8, 218u8, 107u8,
                            117u8, 32u8, 166u8, 2u8,
                        ],
                    )
                }
                #[doc = " Ensure the sequencer address was updated for this block."]
                pub fn seq_addr_update(
                    &self,
                ) -> ::subxt::storage::address::Address<
                    (),
                    types::seq_addr_update::SeqAddrUpdate,
                    ::subxt::storage::address::Yes,
                    ::subxt::storage::address::Yes,
                    (),
                > {
                    ::subxt::storage::address::Address::new_static(
                        "Starknet",
                        "SeqAddrUpdate",
                        (),
                        [
                            86u8, 255u8, 158u8, 112u8, 88u8, 3u8, 203u8, 93u8, 42u8, 28u8, 71u8, 231u8, 161u8, 207u8,
                            222u8, 62u8, 118u8, 196u8, 132u8, 133u8, 33u8, 226u8, 237u8, 95u8, 251u8, 75u8, 142u8,
                            159u8, 110u8, 186u8, 84u8, 189u8,
                        ],
                    )
                }
                #[doc = " Information about processed L1 Messages"]
                #[doc = " Based on Nonce value."]
                pub fn l1_messages(
                    &self,
                ) -> ::subxt::storage::address::Address<
                    (),
                    types::l1_messages::L1Messages,
                    ::subxt::storage::address::Yes,
                    ::subxt::storage::address::Yes,
                    (),
                > {
                    ::subxt::storage::address::Address::new_static(
                        "Starknet",
                        "L1Messages",
                        (),
                        [
                            134u8, 94u8, 210u8, 225u8, 209u8, 59u8, 193u8, 228u8, 58u8, 14u8, 7u8, 117u8, 204u8, 238u8,
                            47u8, 6u8, 101u8, 247u8, 209u8, 127u8, 126u8, 224u8, 8u8, 190u8, 20u8, 126u8, 19u8, 87u8,
                            154u8, 11u8, 152u8, 220u8,
                        ],
                    )
                }
            }
        }
        pub mod constants {
            use super::runtime_types;
            pub struct ConstantsApi;
            impl ConstantsApi {
                #[doc = " The gas price"]
                pub fn l1_gas_price(&self) -> ::subxt::constants::Address<runtime_types::mp_fee::ResourcePrice> {
                    ::subxt::constants::Address::new_static(
                        "Starknet",
                        "L1GasPrice",
                        [
                            144u8, 104u8, 160u8, 190u8, 161u8, 137u8, 14u8, 77u8, 96u8, 91u8, 140u8, 151u8, 150u8,
                            217u8, 205u8, 36u8, 70u8, 81u8, 50u8, 2u8, 79u8, 140u8, 61u8, 37u8, 153u8, 86u8, 60u8,
                            74u8, 56u8, 162u8, 239u8, 139u8,
                        ],
                    )
                }
                #[doc = " A configuration for base priority of unsigned transactions."]
                #[doc = ""]
                #[doc = " This is exposed so that it can be tuned for particular runtime, when"]
                #[doc = " multiple pallets send unsigned transactions."]
                pub fn unsigned_priority(&self) -> ::subxt::constants::Address<::core::primitive::u64> {
                    ::subxt::constants::Address::new_static(
                        "Starknet",
                        "UnsignedPriority",
                        [
                            128u8, 214u8, 205u8, 242u8, 181u8, 142u8, 124u8, 231u8, 190u8, 146u8, 59u8, 226u8, 157u8,
                            101u8, 103u8, 117u8, 249u8, 65u8, 18u8, 191u8, 103u8, 119u8, 53u8, 85u8, 81u8, 96u8, 220u8,
                            42u8, 184u8, 239u8, 42u8, 246u8,
                        ],
                    )
                }
                #[doc = " A configuration for longevity of transactions."]
                #[doc = ""]
                #[doc = " This is exposed so that it can be tuned for particular runtime to"]
                #[doc = " set how long transactions are kept in the mempool."]
                pub fn transaction_longevity(&self) -> ::subxt::constants::Address<::core::primitive::u64> {
                    ::subxt::constants::Address::new_static(
                        "Starknet",
                        "TransactionLongevity",
                        [
                            128u8, 214u8, 205u8, 242u8, 181u8, 142u8, 124u8, 231u8, 190u8, 146u8, 59u8, 226u8, 157u8,
                            101u8, 103u8, 117u8, 249u8, 65u8, 18u8, 191u8, 103u8, 119u8, 53u8, 85u8, 81u8, 96u8, 220u8,
                            42u8, 184u8, 239u8, 42u8, 246u8,
                        ],
                    )
                }
                #[doc = " A bool to disable transaction fees and make all transactions free"]
                pub fn disable_transaction_fee(&self) -> ::subxt::constants::Address<::core::primitive::bool> {
                    ::subxt::constants::Address::new_static(
                        "Starknet",
                        "DisableTransactionFee",
                        [
                            165u8, 28u8, 112u8, 190u8, 18u8, 129u8, 182u8, 206u8, 237u8, 1u8, 68u8, 252u8, 125u8,
                            234u8, 185u8, 50u8, 149u8, 164u8, 47u8, 126u8, 134u8, 100u8, 14u8, 86u8, 209u8, 39u8, 20u8,
                            4u8, 233u8, 115u8, 102u8, 131u8,
                        ],
                    )
                }
                pub fn invoke_tx_max_n_steps(&self) -> ::subxt::constants::Address<::core::primitive::u32> {
                    ::subxt::constants::Address::new_static(
                        "Starknet",
                        "InvokeTxMaxNSteps",
                        [
                            98u8, 252u8, 116u8, 72u8, 26u8, 180u8, 225u8, 83u8, 200u8, 157u8, 125u8, 151u8, 53u8, 76u8,
                            168u8, 26u8, 10u8, 9u8, 98u8, 68u8, 9u8, 178u8, 197u8, 113u8, 31u8, 79u8, 200u8, 90u8,
                            203u8, 100u8, 41u8, 145u8,
                        ],
                    )
                }
                pub fn validate_max_n_steps(&self) -> ::subxt::constants::Address<::core::primitive::u32> {
                    ::subxt::constants::Address::new_static(
                        "Starknet",
                        "ValidateMaxNSteps",
                        [
                            98u8, 252u8, 116u8, 72u8, 26u8, 180u8, 225u8, 83u8, 200u8, 157u8, 125u8, 151u8, 53u8, 76u8,
                            168u8, 26u8, 10u8, 9u8, 98u8, 68u8, 9u8, 178u8, 197u8, 113u8, 31u8, 79u8, 200u8, 90u8,
                            203u8, 100u8, 41u8, 145u8,
                        ],
                    )
                }
                pub fn protocol_version(&self) -> ::subxt::constants::Address<::core::primitive::u8> {
                    ::subxt::constants::Address::new_static(
                        "Starknet",
                        "ProtocolVersion",
                        [
                            141u8, 130u8, 11u8, 35u8, 226u8, 114u8, 92u8, 179u8, 168u8, 110u8, 28u8, 91u8, 221u8, 64u8,
                            4u8, 148u8, 201u8, 193u8, 185u8, 66u8, 226u8, 114u8, 97u8, 79u8, 62u8, 212u8, 202u8, 114u8,
                            237u8, 228u8, 183u8, 165u8,
                        ],
                    )
                }
                pub fn chain_id(&self) -> ::subxt::constants::Address<runtime_types::mp_felt::Felt252Wrapper> {
                    ::subxt::constants::Address::new_static(
                        "Starknet",
                        "ChainId",
                        [
                            115u8, 233u8, 13u8, 223u8, 88u8, 20u8, 202u8, 139u8, 153u8, 28u8, 155u8, 157u8, 224u8,
                            66u8, 3u8, 250u8, 23u8, 53u8, 88u8, 168u8, 211u8, 204u8, 122u8, 166u8, 248u8, 23u8, 174u8,
                            225u8, 99u8, 108u8, 89u8, 135u8,
                        ],
                    )
                }
                pub fn max_recursion_depth(&self) -> ::subxt::constants::Address<::core::primitive::u32> {
                    ::subxt::constants::Address::new_static(
                        "Starknet",
                        "MaxRecursionDepth",
                        [
                            98u8, 252u8, 116u8, 72u8, 26u8, 180u8, 225u8, 83u8, 200u8, 157u8, 125u8, 151u8, 53u8, 76u8,
                            168u8, 26u8, 10u8, 9u8, 98u8, 68u8, 9u8, 178u8, 197u8, 113u8, 31u8, 79u8, 200u8, 90u8,
                            203u8, 100u8, 41u8, 145u8,
                        ],
                    )
                }
                pub fn program_hash(&self) -> ::subxt::constants::Address<runtime_types::mp_felt::Felt252Wrapper> {
                    ::subxt::constants::Address::new_static(
                        "Starknet",
                        "ProgramHash",
                        [
                            115u8, 233u8, 13u8, 223u8, 88u8, 20u8, 202u8, 139u8, 153u8, 28u8, 155u8, 157u8, 224u8,
                            66u8, 3u8, 250u8, 23u8, 53u8, 88u8, 168u8, 211u8, 204u8, 122u8, 166u8, 248u8, 23u8, 174u8,
                            225u8, 99u8, 108u8, 89u8, 135u8,
                        ],
                    )
                }
            }
        }
    }
    pub mod autonomous {
        use super::root_mod;
        use super::runtime_types;
        #[doc = "The pallet custom errors."]
        #[doc = "ERRORS"]
        pub type Error = runtime_types::pallet_autonomous::pallet::Error;
        #[doc = "Contains a variant per dispatchable extrinsic that this pallet has."]
        pub type Call = runtime_types::pallet_autonomous::pallet::Call;
        pub mod calls {
            use super::root_mod;
            use super::runtime_types;
            type DispatchError = runtime_types::sp_runtime::DispatchError;
            pub mod types {
                use super::runtime_types;
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                #[doc = "See [`Pallet::register_job`]."]
                pub struct RegisterJob {
                    pub user_job: register_job::UserJob,
                }
                pub mod register_job {
                    use super::runtime_types;
                    pub type UserJob = runtime_types::pallet_autonomous::types::UserJob;
                }
                impl ::subxt::blocks::StaticExtrinsic for RegisterJob {
                    const PALLET: &'static str = "Autonomous";
                    const CALL: &'static str = "register_job";
                }
            }
            pub struct TransactionApi;
            impl TransactionApi {
                #[doc = "See [`Pallet::register_job`]."]
                pub fn register_job(
                    &self,
                    user_job: types::register_job::UserJob,
                ) -> ::subxt::tx::Payload<types::RegisterJob> {
                    ::subxt::tx::Payload::new_static(
                        "Autonomous",
                        "register_job",
                        types::RegisterJob { user_job },
                        [
                            235u8, 87u8, 42u8, 245u8, 46u8, 177u8, 213u8, 219u8, 227u8, 178u8, 24u8, 223u8, 152u8,
                            17u8, 214u8, 8u8, 194u8, 208u8, 94u8, 33u8, 67u8, 146u8, 166u8, 185u8, 210u8, 210u8, 215u8,
                            150u8, 3u8, 83u8, 60u8, 104u8,
                        ],
                    )
                }
            }
        }
        pub mod storage {
            use super::runtime_types;
            pub mod types {
                use super::runtime_types;
                pub mod jobs {
                    use super::runtime_types;
                    pub type Jobs =
                        ::std::vec::Vec<(::core::primitive::u128, runtime_types::pallet_autonomous::types::Job)>;
                }
                pub mod job_index {
                    use super::runtime_types;
                    pub type JobIndex = ::core::primitive::u64;
                    pub type Param0 = ::core::primitive::u64;
                }
                pub mod job_executed {
                    use super::runtime_types;
                    pub type JobExecuted = ::core::primitive::bool;
                    pub type Param0 = ::core::primitive::u128;
                }
            }
            pub struct StorageApi;
            impl StorageApi {
                pub fn jobs(
                    &self,
                ) -> ::subxt::storage::address::Address<
                    (),
                    types::jobs::Jobs,
                    ::subxt::storage::address::Yes,
                    ::subxt::storage::address::Yes,
                    (),
                > {
                    ::subxt::storage::address::Address::new_static(
                        "Autonomous",
                        "Jobs",
                        (),
                        [
                            35u8, 29u8, 5u8, 140u8, 69u8, 158u8, 192u8, 208u8, 136u8, 99u8, 8u8, 10u8, 134u8, 89u8,
                            94u8, 69u8, 121u8, 204u8, 151u8, 115u8, 41u8, 252u8, 7u8, 214u8, 203u8, 168u8, 229u8, 18u8,
                            4u8, 85u8, 175u8, 174u8,
                        ],
                    )
                }
                pub fn job_index_iter(
                    &self,
                ) -> ::subxt::storage::address::Address<
                    (),
                    types::job_index::JobIndex,
                    (),
                    ::subxt::storage::address::Yes,
                    ::subxt::storage::address::Yes,
                > {
                    ::subxt::storage::address::Address::new_static(
                        "Autonomous",
                        "JobIndex",
                        (),
                        [
                            155u8, 145u8, 200u8, 155u8, 31u8, 32u8, 208u8, 242u8, 124u8, 193u8, 30u8, 200u8, 148u8,
                            188u8, 101u8, 78u8, 155u8, 57u8, 120u8, 95u8, 136u8, 94u8, 13u8, 182u8, 98u8, 137u8, 176u8,
                            242u8, 17u8, 57u8, 67u8, 220u8,
                        ],
                    )
                }
                pub fn job_index(
                    &self,
                    _0: impl ::std::borrow::Borrow<types::job_index::Param0>,
                ) -> ::subxt::storage::address::Address<
                    ::subxt::storage::address::StaticStorageKey<types::job_index::Param0>,
                    types::job_index::JobIndex,
                    ::subxt::storage::address::Yes,
                    ::subxt::storage::address::Yes,
                    (),
                > {
                    ::subxt::storage::address::Address::new_static(
                        "Autonomous",
                        "JobIndex",
                        ::subxt::storage::address::StaticStorageKey::new(_0.borrow()),
                        [
                            155u8, 145u8, 200u8, 155u8, 31u8, 32u8, 208u8, 242u8, 124u8, 193u8, 30u8, 200u8, 148u8,
                            188u8, 101u8, 78u8, 155u8, 57u8, 120u8, 95u8, 136u8, 94u8, 13u8, 182u8, 98u8, 137u8, 176u8,
                            242u8, 17u8, 57u8, 67u8, 220u8,
                        ],
                    )
                }
                pub fn job_executed_iter(
                    &self,
                ) -> ::subxt::storage::address::Address<
                    (),
                    types::job_executed::JobExecuted,
                    (),
                    (),
                    ::subxt::storage::address::Yes,
                > {
                    ::subxt::storage::address::Address::new_static(
                        "Autonomous",
                        "JobExecuted",
                        (),
                        [
                            155u8, 52u8, 157u8, 111u8, 102u8, 208u8, 219u8, 177u8, 103u8, 43u8, 3u8, 122u8, 255u8,
                            139u8, 17u8, 99u8, 187u8, 148u8, 181u8, 244u8, 132u8, 234u8, 176u8, 156u8, 195u8, 246u8,
                            248u8, 157u8, 215u8, 212u8, 194u8, 155u8,
                        ],
                    )
                }
                pub fn job_executed(
                    &self,
                    _0: impl ::std::borrow::Borrow<types::job_executed::Param0>,
                ) -> ::subxt::storage::address::Address<
                    ::subxt::storage::address::StaticStorageKey<types::job_executed::Param0>,
                    types::job_executed::JobExecuted,
                    ::subxt::storage::address::Yes,
                    (),
                    (),
                > {
                    ::subxt::storage::address::Address::new_static(
                        "Autonomous",
                        "JobExecuted",
                        ::subxt::storage::address::StaticStorageKey::new(_0.borrow()),
                        [
                            155u8, 52u8, 157u8, 111u8, 102u8, 208u8, 219u8, 177u8, 103u8, 43u8, 3u8, 122u8, 255u8,
                            139u8, 17u8, 99u8, 187u8, 148u8, 181u8, 244u8, 132u8, 234u8, 176u8, 156u8, 195u8, 246u8,
                            248u8, 157u8, 215u8, 212u8, 194u8, 155u8,
                        ],
                    )
                }
            }
        }
        pub mod constants {
            use super::runtime_types;
            pub struct ConstantsApi;
            impl ConstantsApi {
                #[doc = " Maximum gas allowed for a job."]
                pub fn max_gas(&self) -> ::subxt::constants::Address<::core::primitive::u64> {
                    ::subxt::constants::Address::new_static(
                        "Autonomous",
                        "MaxGas",
                        [
                            128u8, 214u8, 205u8, 242u8, 181u8, 142u8, 124u8, 231u8, 190u8, 146u8, 59u8, 226u8, 157u8,
                            101u8, 103u8, 117u8, 249u8, 65u8, 18u8, 191u8, 103u8, 119u8, 53u8, 85u8, 81u8, 96u8, 220u8,
                            42u8, 184u8, 239u8, 42u8, 246u8,
                        ],
                    )
                }
                #[doc = " Maximum offset allowed for a job. (in blocks)"]
                pub fn validity_max_offset(&self) -> ::subxt::constants::Address<::core::primitive::u64> {
                    ::subxt::constants::Address::new_static(
                        "Autonomous",
                        "ValidityMaxOffset",
                        [
                            128u8, 214u8, 205u8, 242u8, 181u8, 142u8, 124u8, 231u8, 190u8, 146u8, 59u8, 226u8, 157u8,
                            101u8, 103u8, 117u8, 249u8, 65u8, 18u8, 191u8, 103u8, 119u8, 53u8, 85u8, 81u8, 96u8, 220u8,
                            42u8, 184u8, 239u8, 42u8, 246u8,
                        ],
                    )
                }
            }
        }
    }
    pub mod runtime_types {
        use super::runtime_types;
        pub mod blockifier {
            use super::runtime_types;
            pub mod execution {
                use super::runtime_types;
                pub mod contract_class {
                    use super::runtime_types;
                    #[derive(
                        :: subxt :: ext :: codec :: Decode,
                        :: subxt :: ext :: codec :: Encode,
                        :: subxt :: ext :: scale_decode :: DecodeAsType,
                        :: subxt :: ext :: scale_encode :: EncodeAsType,
                        Debug,
                    )]
                    # [codec (crate = :: subxt :: ext :: codec)]
                    #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                    #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                    pub enum ContractClass {
                        #[codec(index = 0)]
                        V0(runtime_types::blockifier::execution::contract_class::ContractClassV0),
                        #[codec(index = 1)]
                        V1(runtime_types::blockifier::execution::contract_class::ContractClassV1),
                    }
                    #[derive(
                        :: subxt :: ext :: codec :: Decode,
                        :: subxt :: ext :: codec :: Encode,
                        :: subxt :: ext :: scale_decode :: DecodeAsType,
                        :: subxt :: ext :: scale_encode :: EncodeAsType,
                        Debug,
                    )]
                    # [codec (crate = :: subxt :: ext :: codec)]
                    #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                    #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                    pub struct ContractClassV0(
                        pub runtime_types::blockifier::execution::contract_class::ContractClassV0Inner,
                    );
                    #[derive(
                        :: subxt :: ext :: codec :: Decode,
                        :: subxt :: ext :: codec :: Encode,
                        :: subxt :: ext :: scale_decode :: DecodeAsType,
                        :: subxt :: ext :: scale_encode :: EncodeAsType,
                        Debug,
                    )]
                    # [codec (crate = :: subxt :: ext :: codec)]
                    #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                    #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                    pub struct ContractClassV0Inner(pub ::std::vec::Vec<::core::primitive::u8>);
                    #[derive(
                        :: subxt :: ext :: codec :: Decode,
                        :: subxt :: ext :: codec :: Encode,
                        :: subxt :: ext :: scale_decode :: DecodeAsType,
                        :: subxt :: ext :: scale_encode :: EncodeAsType,
                        Debug,
                    )]
                    # [codec (crate = :: subxt :: ext :: codec)]
                    #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                    #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                    pub struct ContractClassV1(
                        pub runtime_types::blockifier::execution::contract_class::ContractClassV1Inner,
                    );
                    #[derive(
                        :: subxt :: ext :: codec :: Decode,
                        :: subxt :: ext :: codec :: Encode,
                        :: subxt :: ext :: scale_decode :: DecodeAsType,
                        :: subxt :: ext :: scale_encode :: EncodeAsType,
                        Debug,
                    )]
                    # [codec (crate = :: subxt :: ext :: codec)]
                    #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                    #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                    pub struct ContractClassV1Inner(pub ::std::vec::Vec<::core::primitive::u8>);
                }
            }
            pub mod state {
                use super::runtime_types;
                pub mod cached_state {
                    use super::runtime_types;
                    #[derive(
                        :: subxt :: ext :: codec :: Decode,
                        :: subxt :: ext :: codec :: Encode,
                        :: subxt :: ext :: scale_decode :: DecodeAsType,
                        :: subxt :: ext :: scale_encode :: EncodeAsType,
                        Debug,
                    )]
                    # [codec (crate = :: subxt :: ext :: codec)]
                    #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                    #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                    pub struct CommitmentStateDiff(pub ::std::vec::Vec<::core::primitive::u8>);
                }
            }
            pub mod transaction {
                use super::runtime_types;
                pub mod objects {
                    use super::runtime_types;
                    #[derive(
                        :: subxt :: ext :: codec :: Decode,
                        :: subxt :: ext :: codec :: Encode,
                        :: subxt :: ext :: scale_decode :: DecodeAsType,
                        :: subxt :: ext :: scale_encode :: EncodeAsType,
                        Debug,
                    )]
                    # [codec (crate = :: subxt :: ext :: codec)]
                    #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                    #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                    pub struct TransactionExecutionInfo(pub ::std::vec::Vec<::core::primitive::u8>);
                }
            }
        }
        pub mod bounded_collections {
            use super::runtime_types;
            pub mod bounded_vec {
                use super::runtime_types;
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct BoundedVec<_0>(pub ::std::vec::Vec<_0>);
            }
            pub mod weak_bounded_vec {
                use super::runtime_types;
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct WeakBoundedVec<_0>(pub ::std::vec::Vec<_0>);
            }
        }
        pub mod finality_grandpa {
            use super::runtime_types;
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            pub struct Equivocation<_0, _1, _2> {
                pub round_number: ::core::primitive::u64,
                pub identity: _0,
                pub first: (_1, _2),
                pub second: (_1, _2),
            }
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            pub struct Precommit<_0, _1> {
                pub target_hash: _0,
                pub target_number: _1,
            }
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            pub struct Prevote<_0, _1> {
                pub target_hash: _0,
                pub target_number: _1,
            }
        }
        pub mod frame_support {
            use super::runtime_types;
            pub mod dispatch {
                use super::runtime_types;
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub enum DispatchClass {
                    #[codec(index = 0)]
                    Normal,
                    #[codec(index = 1)]
                    Operational,
                    #[codec(index = 2)]
                    Mandatory,
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct DispatchInfo {
                    pub weight: runtime_types::sp_weights::weight_v2::Weight,
                    pub class: runtime_types::frame_support::dispatch::DispatchClass,
                    pub pays_fee: runtime_types::frame_support::dispatch::Pays,
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub enum Pays {
                    #[codec(index = 0)]
                    Yes,
                    #[codec(index = 1)]
                    No,
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct PerDispatchClass<_0> {
                    pub normal: _0,
                    pub operational: _0,
                    pub mandatory: _0,
                }
            }
        }
        pub mod frame_system {
            use super::runtime_types;
            pub mod extensions {
                use super::runtime_types;
                pub mod check_genesis {
                    use super::runtime_types;
                    #[derive(
                        :: subxt :: ext :: codec :: Decode,
                        :: subxt :: ext :: codec :: Encode,
                        :: subxt :: ext :: scale_decode :: DecodeAsType,
                        :: subxt :: ext :: scale_encode :: EncodeAsType,
                        Debug,
                    )]
                    # [codec (crate = :: subxt :: ext :: codec)]
                    #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                    #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                    pub struct CheckGenesis;
                }
                pub mod check_mortality {
                    use super::runtime_types;
                    #[derive(
                        :: subxt :: ext :: codec :: Decode,
                        :: subxt :: ext :: codec :: Encode,
                        :: subxt :: ext :: scale_decode :: DecodeAsType,
                        :: subxt :: ext :: scale_encode :: EncodeAsType,
                        Debug,
                    )]
                    # [codec (crate = :: subxt :: ext :: codec)]
                    #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                    #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                    pub struct CheckMortality(pub runtime_types::sp_runtime::generic::era::Era);
                }
                pub mod check_non_zero_sender {
                    use super::runtime_types;
                    #[derive(
                        :: subxt :: ext :: codec :: Decode,
                        :: subxt :: ext :: codec :: Encode,
                        :: subxt :: ext :: scale_decode :: DecodeAsType,
                        :: subxt :: ext :: scale_encode :: EncodeAsType,
                        Debug,
                    )]
                    # [codec (crate = :: subxt :: ext :: codec)]
                    #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                    #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                    pub struct CheckNonZeroSender;
                }
                pub mod check_nonce {
                    use super::runtime_types;
                    #[derive(
                        :: subxt :: ext :: codec :: Decode,
                        :: subxt :: ext :: codec :: Encode,
                        :: subxt :: ext :: scale_decode :: DecodeAsType,
                        :: subxt :: ext :: scale_encode :: EncodeAsType,
                        Debug,
                    )]
                    # [codec (crate = :: subxt :: ext :: codec)]
                    #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                    #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                    pub struct CheckNonce(#[codec(compact)] pub ::core::primitive::u32);
                }
                pub mod check_spec_version {
                    use super::runtime_types;
                    #[derive(
                        :: subxt :: ext :: codec :: Decode,
                        :: subxt :: ext :: codec :: Encode,
                        :: subxt :: ext :: scale_decode :: DecodeAsType,
                        :: subxt :: ext :: scale_encode :: EncodeAsType,
                        Debug,
                    )]
                    # [codec (crate = :: subxt :: ext :: codec)]
                    #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                    #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                    pub struct CheckSpecVersion;
                }
                pub mod check_tx_version {
                    use super::runtime_types;
                    #[derive(
                        :: subxt :: ext :: codec :: Decode,
                        :: subxt :: ext :: codec :: Encode,
                        :: subxt :: ext :: scale_decode :: DecodeAsType,
                        :: subxt :: ext :: scale_encode :: EncodeAsType,
                        Debug,
                    )]
                    # [codec (crate = :: subxt :: ext :: codec)]
                    #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                    #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                    pub struct CheckTxVersion;
                }
                pub mod check_weight {
                    use super::runtime_types;
                    #[derive(
                        :: subxt :: ext :: codec :: Decode,
                        :: subxt :: ext :: codec :: Encode,
                        :: subxt :: ext :: scale_decode :: DecodeAsType,
                        :: subxt :: ext :: scale_encode :: EncodeAsType,
                        Debug,
                    )]
                    # [codec (crate = :: subxt :: ext :: codec)]
                    #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                    #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                    pub struct CheckWeight;
                }
            }
            pub mod limits {
                use super::runtime_types;
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct BlockLength {
                    pub max: runtime_types::frame_support::dispatch::PerDispatchClass<::core::primitive::u32>,
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct BlockWeights {
                    pub base_block: runtime_types::sp_weights::weight_v2::Weight,
                    pub max_block: runtime_types::sp_weights::weight_v2::Weight,
                    pub per_class: runtime_types::frame_support::dispatch::PerDispatchClass<
                        runtime_types::frame_system::limits::WeightsPerClass,
                    >,
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct WeightsPerClass {
                    pub base_extrinsic: runtime_types::sp_weights::weight_v2::Weight,
                    pub max_extrinsic: ::core::option::Option<runtime_types::sp_weights::weight_v2::Weight>,
                    pub max_total: ::core::option::Option<runtime_types::sp_weights::weight_v2::Weight>,
                    pub reserved: ::core::option::Option<runtime_types::sp_weights::weight_v2::Weight>,
                }
            }
            pub mod pallet {
                use super::runtime_types;
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                #[doc = "Contains a variant per dispatchable extrinsic that this pallet has."]
                pub enum Call {
                    #[codec(index = 0)]
                    #[doc = "See [`Pallet::remark`]."]
                    remark { remark: ::std::vec::Vec<::core::primitive::u8> },
                    #[codec(index = 1)]
                    #[doc = "See [`Pallet::set_heap_pages`]."]
                    set_heap_pages { pages: ::core::primitive::u64 },
                    #[codec(index = 2)]
                    #[doc = "See [`Pallet::set_code`]."]
                    set_code { code: ::std::vec::Vec<::core::primitive::u8> },
                    #[codec(index = 3)]
                    #[doc = "See [`Pallet::set_code_without_checks`]."]
                    set_code_without_checks { code: ::std::vec::Vec<::core::primitive::u8> },
                    #[codec(index = 4)]
                    #[doc = "See [`Pallet::set_storage`]."]
                    set_storage {
                        items: ::std::vec::Vec<(
                            ::std::vec::Vec<::core::primitive::u8>,
                            ::std::vec::Vec<::core::primitive::u8>,
                        )>,
                    },
                    #[codec(index = 5)]
                    #[doc = "See [`Pallet::kill_storage`]."]
                    kill_storage { keys: ::std::vec::Vec<::std::vec::Vec<::core::primitive::u8>> },
                    #[codec(index = 6)]
                    #[doc = "See [`Pallet::kill_prefix`]."]
                    kill_prefix { prefix: ::std::vec::Vec<::core::primitive::u8>, subkeys: ::core::primitive::u32 },
                    #[codec(index = 7)]
                    #[doc = "See [`Pallet::remark_with_event`]."]
                    remark_with_event { remark: ::std::vec::Vec<::core::primitive::u8> },
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                #[doc = "Error for the System pallet"]
                pub enum Error {
                    #[codec(index = 0)]
                    #[doc = "The name of specification does not match between the current runtime"]
                    #[doc = "and the new runtime."]
                    InvalidSpecName,
                    #[codec(index = 1)]
                    #[doc = "The specification version is not allowed to decrease between the current runtime"]
                    #[doc = "and the new runtime."]
                    SpecVersionNeedsToIncrease,
                    #[codec(index = 2)]
                    #[doc = "Failed to extract the runtime version from the new runtime."]
                    #[doc = ""]
                    #[doc = "Either calling `Core_version` or decoding `RuntimeVersion` failed."]
                    FailedToExtractRuntimeVersion,
                    #[codec(index = 3)]
                    #[doc = "Suicide called when the account has non-default composite data."]
                    NonDefaultComposite,
                    #[codec(index = 4)]
                    #[doc = "There is a non-zero reference count preventing the account from being purged."]
                    NonZeroRefCount,
                    #[codec(index = 5)]
                    #[doc = "The origin filter prevent the call to be dispatched."]
                    CallFiltered,
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                #[doc = "Event for the System pallet."]
                pub enum Event {
                    #[codec(index = 0)]
                    #[doc = "An extrinsic completed successfully."]
                    ExtrinsicSuccess { dispatch_info: runtime_types::frame_support::dispatch::DispatchInfo },
                    #[codec(index = 1)]
                    #[doc = "An extrinsic failed."]
                    ExtrinsicFailed {
                        dispatch_error: runtime_types::sp_runtime::DispatchError,
                        dispatch_info: runtime_types::frame_support::dispatch::DispatchInfo,
                    },
                    #[codec(index = 2)]
                    #[doc = "`:code` was updated."]
                    CodeUpdated,
                    #[codec(index = 3)]
                    #[doc = "A new account was created."]
                    NewAccount { account: ::subxt::utils::AccountId32 },
                    #[codec(index = 4)]
                    #[doc = "An account was reaped."]
                    KilledAccount { account: ::subxt::utils::AccountId32 },
                    #[codec(index = 5)]
                    #[doc = "On on-chain remark happened."]
                    Remarked { sender: ::subxt::utils::AccountId32, hash: ::subxt::utils::H256 },
                }
            }
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            pub struct AccountInfo<_0, _1> {
                pub nonce: _0,
                pub consumers: ::core::primitive::u32,
                pub providers: ::core::primitive::u32,
                pub sufficients: ::core::primitive::u32,
                pub data: _1,
            }
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            pub struct EventRecord<_0, _1> {
                pub phase: runtime_types::frame_system::Phase,
                pub event: _0,
                pub topics: ::std::vec::Vec<_1>,
            }
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            pub struct LastRuntimeUpgradeInfo {
                #[codec(compact)]
                pub spec_version: ::core::primitive::u32,
                pub spec_name: ::std::string::String,
            }
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            pub enum Phase {
                #[codec(index = 0)]
                ApplyExtrinsic(::core::primitive::u32),
                #[codec(index = 1)]
                Finalization,
                #[codec(index = 2)]
                Initialization,
            }
        }
        pub mod madara_runtime {
            use super::runtime_types;
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            pub struct Runtime;
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            pub enum RuntimeCall {
                #[codec(index = 0)]
                System(runtime_types::frame_system::pallet::Call),
                #[codec(index = 1)]
                Timestamp(runtime_types::pallet_timestamp::pallet::Call),
                #[codec(index = 3)]
                Grandpa(runtime_types::pallet_grandpa::pallet::Call),
                #[codec(index = 4)]
                Starknet(runtime_types::pallet_starknet::pallet::Call),
                #[codec(index = 5)]
                Autonomous(runtime_types::pallet_autonomous::pallet::Call),
            }
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            pub enum RuntimeError {
                #[codec(index = 0)]
                System(runtime_types::frame_system::pallet::Error),
                #[codec(index = 3)]
                Grandpa(runtime_types::pallet_grandpa::pallet::Error),
                #[codec(index = 4)]
                Starknet(runtime_types::pallet_starknet::pallet::Error),
                #[codec(index = 5)]
                Autonomous(runtime_types::pallet_autonomous::pallet::Error),
            }
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            pub enum RuntimeEvent {
                #[codec(index = 0)]
                System(runtime_types::frame_system::pallet::Event),
                #[codec(index = 3)]
                Grandpa(runtime_types::pallet_grandpa::pallet::Event),
            }
        }
        pub mod mp_fee {
            use super::runtime_types;
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            pub struct ResourcePrice {
                pub price_in_strk: ::core::option::Option<::core::primitive::u64>,
                pub price_in_wei: ::core::primitive::u128,
            }
        }
        pub mod mp_felt {
            use super::runtime_types;
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            pub struct Felt252Wrapper(pub [::core::primitive::u8; 32usize]);
        }
        pub mod mp_simulations {
            use super::runtime_types;
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            pub struct PlaceHolderErrorTypeForFailedStarknetExecution;
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            pub struct SimulationFlags {
                pub skip_validate: ::core::primitive::bool,
                pub skip_fee_charge: ::core::primitive::bool,
            }
        }
        pub mod mp_transactions {
            use super::runtime_types;
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            pub enum DeclareTransaction {
                #[codec(index = 0)]
                V0(runtime_types::mp_transactions::DeclareTransactionV0),
                #[codec(index = 1)]
                V1(runtime_types::mp_transactions::DeclareTransactionV1),
                #[codec(index = 2)]
                V2(runtime_types::mp_transactions::DeclareTransactionV2),
            }
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            pub struct DeclareTransactionV0 {
                pub max_fee: ::core::primitive::u128,
                pub signature: ::std::vec::Vec<runtime_types::mp_felt::Felt252Wrapper>,
                pub nonce: runtime_types::mp_felt::Felt252Wrapper,
                pub class_hash: runtime_types::mp_felt::Felt252Wrapper,
                pub sender_address: runtime_types::mp_felt::Felt252Wrapper,
            }
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            pub struct DeclareTransactionV1 {
                pub max_fee: ::core::primitive::u128,
                pub signature: ::std::vec::Vec<runtime_types::mp_felt::Felt252Wrapper>,
                pub nonce: runtime_types::mp_felt::Felt252Wrapper,
                pub class_hash: runtime_types::mp_felt::Felt252Wrapper,
                pub sender_address: runtime_types::mp_felt::Felt252Wrapper,
                pub offset_version: ::core::primitive::bool,
            }
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            pub struct DeclareTransactionV2 {
                pub max_fee: ::core::primitive::u128,
                pub signature: ::std::vec::Vec<runtime_types::mp_felt::Felt252Wrapper>,
                pub nonce: runtime_types::mp_felt::Felt252Wrapper,
                pub class_hash: runtime_types::mp_felt::Felt252Wrapper,
                pub sender_address: runtime_types::mp_felt::Felt252Wrapper,
                pub compiled_class_hash: runtime_types::mp_felt::Felt252Wrapper,
                pub offset_version: ::core::primitive::bool,
            }
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            pub struct DeployAccountTransaction {
                pub max_fee: ::core::primitive::u128,
                pub signature: ::std::vec::Vec<runtime_types::mp_felt::Felt252Wrapper>,
                pub nonce: runtime_types::mp_felt::Felt252Wrapper,
                pub contract_address_salt: runtime_types::mp_felt::Felt252Wrapper,
                pub constructor_calldata: ::std::vec::Vec<runtime_types::mp_felt::Felt252Wrapper>,
                pub class_hash: runtime_types::mp_felt::Felt252Wrapper,
                pub offset_version: ::core::primitive::bool,
            }
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            pub struct HandleL1MessageTransaction {
                pub nonce: ::core::primitive::u64,
                pub contract_address: runtime_types::mp_felt::Felt252Wrapper,
                pub entry_point_selector: runtime_types::mp_felt::Felt252Wrapper,
                pub calldata: ::std::vec::Vec<runtime_types::mp_felt::Felt252Wrapper>,
            }
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            pub enum InvokeTransaction {
                #[codec(index = 0)]
                V0(runtime_types::mp_transactions::InvokeTransactionV0),
                #[codec(index = 1)]
                V1(runtime_types::mp_transactions::InvokeTransactionV1),
            }
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            pub struct InvokeTransactionV0 {
                pub max_fee: ::core::primitive::u128,
                pub signature: ::std::vec::Vec<runtime_types::mp_felt::Felt252Wrapper>,
                pub contract_address: runtime_types::mp_felt::Felt252Wrapper,
                pub entry_point_selector: runtime_types::mp_felt::Felt252Wrapper,
                pub calldata: ::std::vec::Vec<runtime_types::mp_felt::Felt252Wrapper>,
            }
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            pub struct InvokeTransactionV1 {
                pub max_fee: ::core::primitive::u128,
                pub signature: ::std::vec::Vec<runtime_types::mp_felt::Felt252Wrapper>,
                pub nonce: runtime_types::mp_felt::Felt252Wrapper,
                pub sender_address: runtime_types::mp_felt::Felt252Wrapper,
                pub calldata: ::std::vec::Vec<runtime_types::mp_felt::Felt252Wrapper>,
                pub offset_version: ::core::primitive::bool,
            }
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            pub enum Transaction {
                #[codec(index = 0)]
                Declare(
                    runtime_types::mp_transactions::DeclareTransaction,
                    runtime_types::blockifier::execution::contract_class::ContractClass,
                ),
                #[codec(index = 1)]
                DeployAccount(runtime_types::mp_transactions::DeployAccountTransaction),
                #[codec(index = 2)]
                Invoke(runtime_types::mp_transactions::InvokeTransaction),
                #[codec(index = 3)]
                L1Handler(runtime_types::mp_transactions::HandleL1MessageTransaction),
            }
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            pub enum UserOrL1HandlerTransaction {
                #[codec(index = 0)]
                User(runtime_types::mp_transactions::UserTransaction),
                #[codec(index = 1)]
                L1Handler(
                    runtime_types::mp_transactions::HandleL1MessageTransaction,
                    runtime_types::starknet_api::transaction::Fee,
                ),
            }
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            pub enum UserTransaction {
                #[codec(index = 0)]
                Declare(
                    runtime_types::mp_transactions::DeclareTransaction,
                    runtime_types::blockifier::execution::contract_class::ContractClass,
                ),
                #[codec(index = 1)]
                DeployAccount(runtime_types::mp_transactions::DeployAccountTransaction),
                #[codec(index = 2)]
                Invoke(runtime_types::mp_transactions::InvokeTransaction),
            }
        }
        pub mod pallet_autonomous {
            use super::runtime_types;
            pub mod pallet {
                use super::runtime_types;
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                #[doc = "Contains a variant per dispatchable extrinsic that this pallet has."]
                pub enum Call {
                    #[codec(index = 0)]
                    #[doc = "See [`Pallet::register_job`]."]
                    register_job { user_job: runtime_types::pallet_autonomous::types::UserJob },
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                #[doc = "The pallet custom errors."]
                #[doc = "ERRORS"]
                pub enum Error {
                    #[codec(index = 0)]
                    JobAlreadyExecuted,
                    #[codec(index = 1)]
                    InvalidJob,
                    #[codec(index = 2)]
                    InvalidJobFrequency,
                    #[codec(index = 3)]
                    JobsLimitReached,
                    #[codec(index = 4)]
                    JobAlreadyRegistered,
                    #[codec(index = 5)]
                    JobGasLimitExceeded,
                }
            }
            pub mod types {
                use super::runtime_types;
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct Job {
                    pub emission_block_number: ::core::primitive::u64,
                    pub index: ::core::primitive::u64,
                    pub max_gas: ::core::primitive::u64,
                    pub actual_gas: ::core::primitive::u64,
                    pub calls: ::std::vec::Vec<runtime_types::mp_transactions::UserTransaction>,
                    pub policy: runtime_types::pallet_autonomous::types::Policy,
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct Policy {
                    pub validity_start: ::core::primitive::u64,
                    pub validity_end: ::core::primitive::u64,
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct UserJob {
                    pub calls: ::std::vec::Vec<::std::vec::Vec<runtime_types::mp_felt::Felt252Wrapper>>,
                    pub policy: runtime_types::pallet_autonomous::types::UserPolicy,
                }
                #[derive(
                    :: subxt :: ext :: codec :: CompactAs,
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct UserPolicy {
                    pub frequency: ::core::primitive::u64,
                }
            }
        }
        pub mod pallet_grandpa {
            use super::runtime_types;
            pub mod pallet {
                use super::runtime_types;
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                #[doc = "Contains a variant per dispatchable extrinsic that this pallet has."]
                pub enum Call {
                    #[codec(index = 0)]
                    #[doc = "See [`Pallet::report_equivocation`]."]
                    report_equivocation {
                        equivocation_proof: ::std::boxed::Box<
                            runtime_types::sp_consensus_grandpa::EquivocationProof<
                                ::subxt::utils::H256,
                                ::core::primitive::u32,
                            >,
                        >,
                        key_owner_proof: runtime_types::sp_core::Void,
                    },
                    #[codec(index = 1)]
                    #[doc = "See [`Pallet::report_equivocation_unsigned`]."]
                    report_equivocation_unsigned {
                        equivocation_proof: ::std::boxed::Box<
                            runtime_types::sp_consensus_grandpa::EquivocationProof<
                                ::subxt::utils::H256,
                                ::core::primitive::u32,
                            >,
                        >,
                        key_owner_proof: runtime_types::sp_core::Void,
                    },
                    #[codec(index = 2)]
                    #[doc = "See [`Pallet::note_stalled`]."]
                    note_stalled { delay: ::core::primitive::u32, best_finalized_block_number: ::core::primitive::u32 },
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                #[doc = "The `Error` enum of this pallet."]
                pub enum Error {
                    #[codec(index = 0)]
                    #[doc = "Attempt to signal GRANDPA pause when the authority set isn't live"]
                    #[doc = "(either paused or already pending pause)."]
                    PauseFailed,
                    #[codec(index = 1)]
                    #[doc = "Attempt to signal GRANDPA resume when the authority set isn't paused"]
                    #[doc = "(either live or already pending resume)."]
                    ResumeFailed,
                    #[codec(index = 2)]
                    #[doc = "Attempt to signal GRANDPA change with one already pending."]
                    ChangePending,
                    #[codec(index = 3)]
                    #[doc = "Cannot signal forced change so soon after last."]
                    TooSoon,
                    #[codec(index = 4)]
                    #[doc = "A key ownership proof provided as part of an equivocation report is invalid."]
                    InvalidKeyOwnershipProof,
                    #[codec(index = 5)]
                    #[doc = "An equivocation proof provided as part of an equivocation report is invalid."]
                    InvalidEquivocationProof,
                    #[codec(index = 6)]
                    #[doc = "A given equivocation report is valid but already previously reported."]
                    DuplicateOffenceReport,
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                #[doc = "The `Event` enum of this pallet"]
                pub enum Event {
                    #[codec(index = 0)]
                    #[doc = "New authority set has been applied."]
                    NewAuthorities {
                        authority_set:
                            ::std::vec::Vec<(runtime_types::sp_consensus_grandpa::app::Public, ::core::primitive::u64)>,
                    },
                    #[codec(index = 1)]
                    #[doc = "Current authority set has been paused."]
                    Paused,
                    #[codec(index = 2)]
                    #[doc = "Current authority set has been resumed."]
                    Resumed,
                }
            }
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            pub struct StoredPendingChange<_0> {
                pub scheduled_at: _0,
                pub delay: _0,
                pub next_authorities: runtime_types::bounded_collections::weak_bounded_vec::WeakBoundedVec<(
                    runtime_types::sp_consensus_grandpa::app::Public,
                    ::core::primitive::u64,
                )>,
                pub forced: ::core::option::Option<_0>,
            }
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            pub enum StoredState<_0> {
                #[codec(index = 0)]
                Live,
                #[codec(index = 1)]
                PendingPause { scheduled_at: _0, delay: _0 },
                #[codec(index = 2)]
                Paused,
                #[codec(index = 3)]
                PendingResume { scheduled_at: _0, delay: _0 },
            }
        }
        pub mod pallet_starknet {
            use super::runtime_types;
            pub mod pallet {
                use super::runtime_types;
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                #[doc = "The Starknet pallet external functions."]
                #[doc = "Dispatchable functions allows users to interact with the pallet and invoke state changes."]
                #[doc = "These functions materialize as \"extrinsics\", which are often compared to transactions."]
                #[doc = "Dispatchable functions must be annotated with a weight and must return a DispatchResult."]
                pub enum Call {
                    #[codec(index = 0)]
                    #[doc = "See [`Pallet::set_sequencer_address`]."]
                    set_sequencer_address { addr: [::core::primitive::u8; 32usize] },
                    #[codec(index = 1)]
                    #[doc = "See [`Pallet::invoke`]."]
                    invoke { transaction: runtime_types::mp_transactions::InvokeTransaction },
                    #[codec(index = 2)]
                    #[doc = "See [`Pallet::declare`]."]
                    declare {
                        transaction: runtime_types::mp_transactions::DeclareTransaction,
                        contract_class: runtime_types::blockifier::execution::contract_class::ContractClass,
                    },
                    #[codec(index = 3)]
                    #[doc = "See [`Pallet::deploy_account`]."]
                    deploy_account { transaction: runtime_types::mp_transactions::DeployAccountTransaction },
                    #[codec(index = 4)]
                    #[doc = "See [`Pallet::consume_l1_message`]."]
                    consume_l1_message {
                        transaction: runtime_types::mp_transactions::HandleL1MessageTransaction,
                        paid_fee_on_l1: runtime_types::starknet_api::transaction::Fee,
                    },
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                #[doc = "The Starknet pallet custom errors."]
                #[doc = "ERRORS"]
                pub enum Error {
                    #[codec(index = 0)]
                    AccountNotDeployed,
                    #[codec(index = 1)]
                    TransactionExecutionFailed,
                    #[codec(index = 2)]
                    ClassHashAlreadyDeclared,
                    #[codec(index = 3)]
                    ContractClassHashUnknown,
                    #[codec(index = 4)]
                    ContractClassAlreadyAssociated,
                    #[codec(index = 5)]
                    ContractClassMustBeSpecified,
                    #[codec(index = 6)]
                    AccountAlreadyDeployed,
                    #[codec(index = 7)]
                    ContractAddressAlreadyAssociated,
                    #[codec(index = 8)]
                    InvalidContractClass,
                    #[codec(index = 9)]
                    TooManyEmittedStarknetEvents,
                    #[codec(index = 10)]
                    StateReaderError,
                    #[codec(index = 11)]
                    EmitEventError,
                    #[codec(index = 12)]
                    StateDiffError,
                    #[codec(index = 13)]
                    ContractNotFound,
                    #[codec(index = 14)]
                    TransactionConversionError,
                    #[codec(index = 15)]
                    SequencerAddressNotValid,
                    #[codec(index = 16)]
                    InvalidContractClassForThisDeclareVersion,
                    #[codec(index = 17)]
                    Unimplemented,
                    #[codec(index = 18)]
                    MissingRevertReason,
                    #[codec(index = 19)]
                    MissingCallInfo,
                    #[codec(index = 20)]
                    FailedToCreateATransactionalStorageExecution,
                    #[codec(index = 21)]
                    L1MessageAlreadyExecuted,
                    #[codec(index = 22)]
                    MissingL1GasUsage,
                }
            }
        }
        pub mod pallet_starknet_runtime_api {
            use super::runtime_types;
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            pub struct BlockContext {
                pub chain_id: ::std::string::String,
                pub block_number: ::core::primitive::u64,
                pub block_timestamp: ::core::primitive::u64,
                pub sequencer_address: runtime_types::starknet_api::api_core::ContractAddress,
                pub fee_token_address: runtime_types::starknet_api::api_core::ContractAddress,
                pub vm_resource_fee_cost:
                    ::std::vec::Vec<(::std::string::String, runtime_types::sp_arithmetic::fixed_point::FixedU128)>,
                pub gas_price: ::core::primitive::u128,
                pub invoke_tx_max_n_steps: ::core::primitive::u32,
                pub validate_max_n_steps: ::core::primitive::u32,
                pub max_recursion_depth: ::core::primitive::u32,
            }
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            pub enum StarknetTransactionExecutionError {
                #[codec(index = 0)]
                ContractNotFound,
                #[codec(index = 1)]
                ClassAlreadyDeclared,
                #[codec(index = 2)]
                ClassHashNotFound,
                #[codec(index = 3)]
                InvalidContractClass,
                #[codec(index = 4)]
                ContractError,
            }
        }
        pub mod pallet_timestamp {
            use super::runtime_types;
            pub mod pallet {
                use super::runtime_types;
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                #[doc = "Contains a variant per dispatchable extrinsic that this pallet has."]
                pub enum Call {
                    #[codec(index = 0)]
                    #[doc = "See [`Pallet::set`]."]
                    set {
                        #[codec(compact)]
                        now: ::core::primitive::u64,
                    },
                }
            }
        }
        pub mod sp_arithmetic {
            use super::runtime_types;
            pub mod fixed_point {
                use super::runtime_types;
                #[derive(
                    :: subxt :: ext :: codec :: CompactAs,
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct FixedU128(pub ::core::primitive::u128);
            }
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            pub enum ArithmeticError {
                #[codec(index = 0)]
                Underflow,
                #[codec(index = 1)]
                Overflow,
                #[codec(index = 2)]
                DivisionByZero,
            }
        }
        pub mod sp_consensus_aura {
            use super::runtime_types;
            pub mod sr25519 {
                use super::runtime_types;
                pub mod app_sr25519 {
                    use super::runtime_types;
                    #[derive(
                        :: subxt :: ext :: codec :: Decode,
                        :: subxt :: ext :: codec :: Encode,
                        :: subxt :: ext :: scale_decode :: DecodeAsType,
                        :: subxt :: ext :: scale_encode :: EncodeAsType,
                        Debug,
                    )]
                    # [codec (crate = :: subxt :: ext :: codec)]
                    #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                    #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                    pub struct Public(pub runtime_types::sp_core::sr25519::Public);
                }
            }
        }
        pub mod sp_consensus_grandpa {
            use super::runtime_types;
            pub mod app {
                use super::runtime_types;
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct Public(pub runtime_types::sp_core::ed25519::Public);
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct Signature(pub runtime_types::sp_core::ed25519::Signature);
            }
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            pub enum Equivocation<_0, _1> {
                #[codec(index = 0)]
                Prevote(
                    runtime_types::finality_grandpa::Equivocation<
                        runtime_types::sp_consensus_grandpa::app::Public,
                        runtime_types::finality_grandpa::Prevote<_0, _1>,
                        runtime_types::sp_consensus_grandpa::app::Signature,
                    >,
                ),
                #[codec(index = 1)]
                Precommit(
                    runtime_types::finality_grandpa::Equivocation<
                        runtime_types::sp_consensus_grandpa::app::Public,
                        runtime_types::finality_grandpa::Precommit<_0, _1>,
                        runtime_types::sp_consensus_grandpa::app::Signature,
                    >,
                ),
            }
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            pub struct EquivocationProof<_0, _1> {
                pub set_id: ::core::primitive::u64,
                pub equivocation: runtime_types::sp_consensus_grandpa::Equivocation<_0, _1>,
            }
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            pub struct OpaqueKeyOwnershipProof(pub ::std::vec::Vec<::core::primitive::u8>);
        }
        pub mod sp_consensus_slots {
            use super::runtime_types;
            #[derive(
                :: subxt :: ext :: codec :: CompactAs,
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            pub struct Slot(pub ::core::primitive::u64);
            #[derive(
                :: subxt :: ext :: codec :: CompactAs,
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            pub struct SlotDuration(pub ::core::primitive::u64);
        }
        pub mod sp_core {
            use super::runtime_types;
            pub mod crypto {
                use super::runtime_types;
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct KeyTypeId(pub [::core::primitive::u8; 4usize]);
            }
            pub mod ecdsa {
                use super::runtime_types;
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct Signature(pub [::core::primitive::u8; 65usize]);
            }
            pub mod ed25519 {
                use super::runtime_types;
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct Public(pub [::core::primitive::u8; 32usize]);
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct Signature(pub [::core::primitive::u8; 64usize]);
            }
            pub mod sr25519 {
                use super::runtime_types;
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct Public(pub [::core::primitive::u8; 32usize]);
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct Signature(pub [::core::primitive::u8; 64usize]);
            }
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            pub struct OpaqueMetadata(pub ::std::vec::Vec<::core::primitive::u8>);
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            pub enum Void {}
        }
        pub mod sp_inherents {
            use super::runtime_types;
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            pub struct CheckInherentsResult {
                pub okay: ::core::primitive::bool,
                pub fatal_error: ::core::primitive::bool,
                pub errors: runtime_types::sp_inherents::InherentData,
            }
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            pub struct InherentData {
                pub data:
                    ::subxt::utils::KeyedVec<[::core::primitive::u8; 8usize], ::std::vec::Vec<::core::primitive::u8>>,
            }
        }
        pub mod sp_runtime {
            use super::runtime_types;
            pub mod generic {
                use super::runtime_types;
                pub mod block {
                    use super::runtime_types;
                    #[derive(
                        :: subxt :: ext :: codec :: Decode,
                        :: subxt :: ext :: codec :: Encode,
                        :: subxt :: ext :: scale_decode :: DecodeAsType,
                        :: subxt :: ext :: scale_encode :: EncodeAsType,
                        Debug,
                    )]
                    # [codec (crate = :: subxt :: ext :: codec)]
                    #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                    #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                    pub struct Block<_0, _1> {
                        pub header: _0,
                        pub extrinsics: ::std::vec::Vec<_1>,
                    }
                }
                pub mod digest {
                    use super::runtime_types;
                    #[derive(
                        :: subxt :: ext :: codec :: Decode,
                        :: subxt :: ext :: codec :: Encode,
                        :: subxt :: ext :: scale_decode :: DecodeAsType,
                        :: subxt :: ext :: scale_encode :: EncodeAsType,
                        Debug,
                    )]
                    # [codec (crate = :: subxt :: ext :: codec)]
                    #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                    #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                    pub struct Digest {
                        pub logs: ::std::vec::Vec<runtime_types::sp_runtime::generic::digest::DigestItem>,
                    }
                    #[derive(
                        :: subxt :: ext :: codec :: Decode,
                        :: subxt :: ext :: codec :: Encode,
                        :: subxt :: ext :: scale_decode :: DecodeAsType,
                        :: subxt :: ext :: scale_encode :: EncodeAsType,
                        Debug,
                    )]
                    # [codec (crate = :: subxt :: ext :: codec)]
                    #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                    #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                    pub enum DigestItem {
                        #[codec(index = 6)]
                        PreRuntime([::core::primitive::u8; 4usize], ::std::vec::Vec<::core::primitive::u8>),
                        #[codec(index = 4)]
                        Consensus([::core::primitive::u8; 4usize], ::std::vec::Vec<::core::primitive::u8>),
                        #[codec(index = 5)]
                        Seal([::core::primitive::u8; 4usize], ::std::vec::Vec<::core::primitive::u8>),
                        #[codec(index = 0)]
                        Other(::std::vec::Vec<::core::primitive::u8>),
                        #[codec(index = 8)]
                        RuntimeEnvironmentUpdated,
                    }
                }
                pub mod era {
                    use super::runtime_types;
                    #[derive(
                        :: subxt :: ext :: codec :: Decode,
                        :: subxt :: ext :: codec :: Encode,
                        :: subxt :: ext :: scale_decode :: DecodeAsType,
                        :: subxt :: ext :: scale_encode :: EncodeAsType,
                        Debug,
                    )]
                    # [codec (crate = :: subxt :: ext :: codec)]
                    #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                    #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                    pub enum Era {
                        #[codec(index = 0)]
                        Immortal,
                        #[codec(index = 1)]
                        Mortal1(::core::primitive::u8),
                        #[codec(index = 2)]
                        Mortal2(::core::primitive::u8),
                        #[codec(index = 3)]
                        Mortal3(::core::primitive::u8),
                        #[codec(index = 4)]
                        Mortal4(::core::primitive::u8),
                        #[codec(index = 5)]
                        Mortal5(::core::primitive::u8),
                        #[codec(index = 6)]
                        Mortal6(::core::primitive::u8),
                        #[codec(index = 7)]
                        Mortal7(::core::primitive::u8),
                        #[codec(index = 8)]
                        Mortal8(::core::primitive::u8),
                        #[codec(index = 9)]
                        Mortal9(::core::primitive::u8),
                        #[codec(index = 10)]
                        Mortal10(::core::primitive::u8),
                        #[codec(index = 11)]
                        Mortal11(::core::primitive::u8),
                        #[codec(index = 12)]
                        Mortal12(::core::primitive::u8),
                        #[codec(index = 13)]
                        Mortal13(::core::primitive::u8),
                        #[codec(index = 14)]
                        Mortal14(::core::primitive::u8),
                        #[codec(index = 15)]
                        Mortal15(::core::primitive::u8),
                        #[codec(index = 16)]
                        Mortal16(::core::primitive::u8),
                        #[codec(index = 17)]
                        Mortal17(::core::primitive::u8),
                        #[codec(index = 18)]
                        Mortal18(::core::primitive::u8),
                        #[codec(index = 19)]
                        Mortal19(::core::primitive::u8),
                        #[codec(index = 20)]
                        Mortal20(::core::primitive::u8),
                        #[codec(index = 21)]
                        Mortal21(::core::primitive::u8),
                        #[codec(index = 22)]
                        Mortal22(::core::primitive::u8),
                        #[codec(index = 23)]
                        Mortal23(::core::primitive::u8),
                        #[codec(index = 24)]
                        Mortal24(::core::primitive::u8),
                        #[codec(index = 25)]
                        Mortal25(::core::primitive::u8),
                        #[codec(index = 26)]
                        Mortal26(::core::primitive::u8),
                        #[codec(index = 27)]
                        Mortal27(::core::primitive::u8),
                        #[codec(index = 28)]
                        Mortal28(::core::primitive::u8),
                        #[codec(index = 29)]
                        Mortal29(::core::primitive::u8),
                        #[codec(index = 30)]
                        Mortal30(::core::primitive::u8),
                        #[codec(index = 31)]
                        Mortal31(::core::primitive::u8),
                        #[codec(index = 32)]
                        Mortal32(::core::primitive::u8),
                        #[codec(index = 33)]
                        Mortal33(::core::primitive::u8),
                        #[codec(index = 34)]
                        Mortal34(::core::primitive::u8),
                        #[codec(index = 35)]
                        Mortal35(::core::primitive::u8),
                        #[codec(index = 36)]
                        Mortal36(::core::primitive::u8),
                        #[codec(index = 37)]
                        Mortal37(::core::primitive::u8),
                        #[codec(index = 38)]
                        Mortal38(::core::primitive::u8),
                        #[codec(index = 39)]
                        Mortal39(::core::primitive::u8),
                        #[codec(index = 40)]
                        Mortal40(::core::primitive::u8),
                        #[codec(index = 41)]
                        Mortal41(::core::primitive::u8),
                        #[codec(index = 42)]
                        Mortal42(::core::primitive::u8),
                        #[codec(index = 43)]
                        Mortal43(::core::primitive::u8),
                        #[codec(index = 44)]
                        Mortal44(::core::primitive::u8),
                        #[codec(index = 45)]
                        Mortal45(::core::primitive::u8),
                        #[codec(index = 46)]
                        Mortal46(::core::primitive::u8),
                        #[codec(index = 47)]
                        Mortal47(::core::primitive::u8),
                        #[codec(index = 48)]
                        Mortal48(::core::primitive::u8),
                        #[codec(index = 49)]
                        Mortal49(::core::primitive::u8),
                        #[codec(index = 50)]
                        Mortal50(::core::primitive::u8),
                        #[codec(index = 51)]
                        Mortal51(::core::primitive::u8),
                        #[codec(index = 52)]
                        Mortal52(::core::primitive::u8),
                        #[codec(index = 53)]
                        Mortal53(::core::primitive::u8),
                        #[codec(index = 54)]
                        Mortal54(::core::primitive::u8),
                        #[codec(index = 55)]
                        Mortal55(::core::primitive::u8),
                        #[codec(index = 56)]
                        Mortal56(::core::primitive::u8),
                        #[codec(index = 57)]
                        Mortal57(::core::primitive::u8),
                        #[codec(index = 58)]
                        Mortal58(::core::primitive::u8),
                        #[codec(index = 59)]
                        Mortal59(::core::primitive::u8),
                        #[codec(index = 60)]
                        Mortal60(::core::primitive::u8),
                        #[codec(index = 61)]
                        Mortal61(::core::primitive::u8),
                        #[codec(index = 62)]
                        Mortal62(::core::primitive::u8),
                        #[codec(index = 63)]
                        Mortal63(::core::primitive::u8),
                        #[codec(index = 64)]
                        Mortal64(::core::primitive::u8),
                        #[codec(index = 65)]
                        Mortal65(::core::primitive::u8),
                        #[codec(index = 66)]
                        Mortal66(::core::primitive::u8),
                        #[codec(index = 67)]
                        Mortal67(::core::primitive::u8),
                        #[codec(index = 68)]
                        Mortal68(::core::primitive::u8),
                        #[codec(index = 69)]
                        Mortal69(::core::primitive::u8),
                        #[codec(index = 70)]
                        Mortal70(::core::primitive::u8),
                        #[codec(index = 71)]
                        Mortal71(::core::primitive::u8),
                        #[codec(index = 72)]
                        Mortal72(::core::primitive::u8),
                        #[codec(index = 73)]
                        Mortal73(::core::primitive::u8),
                        #[codec(index = 74)]
                        Mortal74(::core::primitive::u8),
                        #[codec(index = 75)]
                        Mortal75(::core::primitive::u8),
                        #[codec(index = 76)]
                        Mortal76(::core::primitive::u8),
                        #[codec(index = 77)]
                        Mortal77(::core::primitive::u8),
                        #[codec(index = 78)]
                        Mortal78(::core::primitive::u8),
                        #[codec(index = 79)]
                        Mortal79(::core::primitive::u8),
                        #[codec(index = 80)]
                        Mortal80(::core::primitive::u8),
                        #[codec(index = 81)]
                        Mortal81(::core::primitive::u8),
                        #[codec(index = 82)]
                        Mortal82(::core::primitive::u8),
                        #[codec(index = 83)]
                        Mortal83(::core::primitive::u8),
                        #[codec(index = 84)]
                        Mortal84(::core::primitive::u8),
                        #[codec(index = 85)]
                        Mortal85(::core::primitive::u8),
                        #[codec(index = 86)]
                        Mortal86(::core::primitive::u8),
                        #[codec(index = 87)]
                        Mortal87(::core::primitive::u8),
                        #[codec(index = 88)]
                        Mortal88(::core::primitive::u8),
                        #[codec(index = 89)]
                        Mortal89(::core::primitive::u8),
                        #[codec(index = 90)]
                        Mortal90(::core::primitive::u8),
                        #[codec(index = 91)]
                        Mortal91(::core::primitive::u8),
                        #[codec(index = 92)]
                        Mortal92(::core::primitive::u8),
                        #[codec(index = 93)]
                        Mortal93(::core::primitive::u8),
                        #[codec(index = 94)]
                        Mortal94(::core::primitive::u8),
                        #[codec(index = 95)]
                        Mortal95(::core::primitive::u8),
                        #[codec(index = 96)]
                        Mortal96(::core::primitive::u8),
                        #[codec(index = 97)]
                        Mortal97(::core::primitive::u8),
                        #[codec(index = 98)]
                        Mortal98(::core::primitive::u8),
                        #[codec(index = 99)]
                        Mortal99(::core::primitive::u8),
                        #[codec(index = 100)]
                        Mortal100(::core::primitive::u8),
                        #[codec(index = 101)]
                        Mortal101(::core::primitive::u8),
                        #[codec(index = 102)]
                        Mortal102(::core::primitive::u8),
                        #[codec(index = 103)]
                        Mortal103(::core::primitive::u8),
                        #[codec(index = 104)]
                        Mortal104(::core::primitive::u8),
                        #[codec(index = 105)]
                        Mortal105(::core::primitive::u8),
                        #[codec(index = 106)]
                        Mortal106(::core::primitive::u8),
                        #[codec(index = 107)]
                        Mortal107(::core::primitive::u8),
                        #[codec(index = 108)]
                        Mortal108(::core::primitive::u8),
                        #[codec(index = 109)]
                        Mortal109(::core::primitive::u8),
                        #[codec(index = 110)]
                        Mortal110(::core::primitive::u8),
                        #[codec(index = 111)]
                        Mortal111(::core::primitive::u8),
                        #[codec(index = 112)]
                        Mortal112(::core::primitive::u8),
                        #[codec(index = 113)]
                        Mortal113(::core::primitive::u8),
                        #[codec(index = 114)]
                        Mortal114(::core::primitive::u8),
                        #[codec(index = 115)]
                        Mortal115(::core::primitive::u8),
                        #[codec(index = 116)]
                        Mortal116(::core::primitive::u8),
                        #[codec(index = 117)]
                        Mortal117(::core::primitive::u8),
                        #[codec(index = 118)]
                        Mortal118(::core::primitive::u8),
                        #[codec(index = 119)]
                        Mortal119(::core::primitive::u8),
                        #[codec(index = 120)]
                        Mortal120(::core::primitive::u8),
                        #[codec(index = 121)]
                        Mortal121(::core::primitive::u8),
                        #[codec(index = 122)]
                        Mortal122(::core::primitive::u8),
                        #[codec(index = 123)]
                        Mortal123(::core::primitive::u8),
                        #[codec(index = 124)]
                        Mortal124(::core::primitive::u8),
                        #[codec(index = 125)]
                        Mortal125(::core::primitive::u8),
                        #[codec(index = 126)]
                        Mortal126(::core::primitive::u8),
                        #[codec(index = 127)]
                        Mortal127(::core::primitive::u8),
                        #[codec(index = 128)]
                        Mortal128(::core::primitive::u8),
                        #[codec(index = 129)]
                        Mortal129(::core::primitive::u8),
                        #[codec(index = 130)]
                        Mortal130(::core::primitive::u8),
                        #[codec(index = 131)]
                        Mortal131(::core::primitive::u8),
                        #[codec(index = 132)]
                        Mortal132(::core::primitive::u8),
                        #[codec(index = 133)]
                        Mortal133(::core::primitive::u8),
                        #[codec(index = 134)]
                        Mortal134(::core::primitive::u8),
                        #[codec(index = 135)]
                        Mortal135(::core::primitive::u8),
                        #[codec(index = 136)]
                        Mortal136(::core::primitive::u8),
                        #[codec(index = 137)]
                        Mortal137(::core::primitive::u8),
                        #[codec(index = 138)]
                        Mortal138(::core::primitive::u8),
                        #[codec(index = 139)]
                        Mortal139(::core::primitive::u8),
                        #[codec(index = 140)]
                        Mortal140(::core::primitive::u8),
                        #[codec(index = 141)]
                        Mortal141(::core::primitive::u8),
                        #[codec(index = 142)]
                        Mortal142(::core::primitive::u8),
                        #[codec(index = 143)]
                        Mortal143(::core::primitive::u8),
                        #[codec(index = 144)]
                        Mortal144(::core::primitive::u8),
                        #[codec(index = 145)]
                        Mortal145(::core::primitive::u8),
                        #[codec(index = 146)]
                        Mortal146(::core::primitive::u8),
                        #[codec(index = 147)]
                        Mortal147(::core::primitive::u8),
                        #[codec(index = 148)]
                        Mortal148(::core::primitive::u8),
                        #[codec(index = 149)]
                        Mortal149(::core::primitive::u8),
                        #[codec(index = 150)]
                        Mortal150(::core::primitive::u8),
                        #[codec(index = 151)]
                        Mortal151(::core::primitive::u8),
                        #[codec(index = 152)]
                        Mortal152(::core::primitive::u8),
                        #[codec(index = 153)]
                        Mortal153(::core::primitive::u8),
                        #[codec(index = 154)]
                        Mortal154(::core::primitive::u8),
                        #[codec(index = 155)]
                        Mortal155(::core::primitive::u8),
                        #[codec(index = 156)]
                        Mortal156(::core::primitive::u8),
                        #[codec(index = 157)]
                        Mortal157(::core::primitive::u8),
                        #[codec(index = 158)]
                        Mortal158(::core::primitive::u8),
                        #[codec(index = 159)]
                        Mortal159(::core::primitive::u8),
                        #[codec(index = 160)]
                        Mortal160(::core::primitive::u8),
                        #[codec(index = 161)]
                        Mortal161(::core::primitive::u8),
                        #[codec(index = 162)]
                        Mortal162(::core::primitive::u8),
                        #[codec(index = 163)]
                        Mortal163(::core::primitive::u8),
                        #[codec(index = 164)]
                        Mortal164(::core::primitive::u8),
                        #[codec(index = 165)]
                        Mortal165(::core::primitive::u8),
                        #[codec(index = 166)]
                        Mortal166(::core::primitive::u8),
                        #[codec(index = 167)]
                        Mortal167(::core::primitive::u8),
                        #[codec(index = 168)]
                        Mortal168(::core::primitive::u8),
                        #[codec(index = 169)]
                        Mortal169(::core::primitive::u8),
                        #[codec(index = 170)]
                        Mortal170(::core::primitive::u8),
                        #[codec(index = 171)]
                        Mortal171(::core::primitive::u8),
                        #[codec(index = 172)]
                        Mortal172(::core::primitive::u8),
                        #[codec(index = 173)]
                        Mortal173(::core::primitive::u8),
                        #[codec(index = 174)]
                        Mortal174(::core::primitive::u8),
                        #[codec(index = 175)]
                        Mortal175(::core::primitive::u8),
                        #[codec(index = 176)]
                        Mortal176(::core::primitive::u8),
                        #[codec(index = 177)]
                        Mortal177(::core::primitive::u8),
                        #[codec(index = 178)]
                        Mortal178(::core::primitive::u8),
                        #[codec(index = 179)]
                        Mortal179(::core::primitive::u8),
                        #[codec(index = 180)]
                        Mortal180(::core::primitive::u8),
                        #[codec(index = 181)]
                        Mortal181(::core::primitive::u8),
                        #[codec(index = 182)]
                        Mortal182(::core::primitive::u8),
                        #[codec(index = 183)]
                        Mortal183(::core::primitive::u8),
                        #[codec(index = 184)]
                        Mortal184(::core::primitive::u8),
                        #[codec(index = 185)]
                        Mortal185(::core::primitive::u8),
                        #[codec(index = 186)]
                        Mortal186(::core::primitive::u8),
                        #[codec(index = 187)]
                        Mortal187(::core::primitive::u8),
                        #[codec(index = 188)]
                        Mortal188(::core::primitive::u8),
                        #[codec(index = 189)]
                        Mortal189(::core::primitive::u8),
                        #[codec(index = 190)]
                        Mortal190(::core::primitive::u8),
                        #[codec(index = 191)]
                        Mortal191(::core::primitive::u8),
                        #[codec(index = 192)]
                        Mortal192(::core::primitive::u8),
                        #[codec(index = 193)]
                        Mortal193(::core::primitive::u8),
                        #[codec(index = 194)]
                        Mortal194(::core::primitive::u8),
                        #[codec(index = 195)]
                        Mortal195(::core::primitive::u8),
                        #[codec(index = 196)]
                        Mortal196(::core::primitive::u8),
                        #[codec(index = 197)]
                        Mortal197(::core::primitive::u8),
                        #[codec(index = 198)]
                        Mortal198(::core::primitive::u8),
                        #[codec(index = 199)]
                        Mortal199(::core::primitive::u8),
                        #[codec(index = 200)]
                        Mortal200(::core::primitive::u8),
                        #[codec(index = 201)]
                        Mortal201(::core::primitive::u8),
                        #[codec(index = 202)]
                        Mortal202(::core::primitive::u8),
                        #[codec(index = 203)]
                        Mortal203(::core::primitive::u8),
                        #[codec(index = 204)]
                        Mortal204(::core::primitive::u8),
                        #[codec(index = 205)]
                        Mortal205(::core::primitive::u8),
                        #[codec(index = 206)]
                        Mortal206(::core::primitive::u8),
                        #[codec(index = 207)]
                        Mortal207(::core::primitive::u8),
                        #[codec(index = 208)]
                        Mortal208(::core::primitive::u8),
                        #[codec(index = 209)]
                        Mortal209(::core::primitive::u8),
                        #[codec(index = 210)]
                        Mortal210(::core::primitive::u8),
                        #[codec(index = 211)]
                        Mortal211(::core::primitive::u8),
                        #[codec(index = 212)]
                        Mortal212(::core::primitive::u8),
                        #[codec(index = 213)]
                        Mortal213(::core::primitive::u8),
                        #[codec(index = 214)]
                        Mortal214(::core::primitive::u8),
                        #[codec(index = 215)]
                        Mortal215(::core::primitive::u8),
                        #[codec(index = 216)]
                        Mortal216(::core::primitive::u8),
                        #[codec(index = 217)]
                        Mortal217(::core::primitive::u8),
                        #[codec(index = 218)]
                        Mortal218(::core::primitive::u8),
                        #[codec(index = 219)]
                        Mortal219(::core::primitive::u8),
                        #[codec(index = 220)]
                        Mortal220(::core::primitive::u8),
                        #[codec(index = 221)]
                        Mortal221(::core::primitive::u8),
                        #[codec(index = 222)]
                        Mortal222(::core::primitive::u8),
                        #[codec(index = 223)]
                        Mortal223(::core::primitive::u8),
                        #[codec(index = 224)]
                        Mortal224(::core::primitive::u8),
                        #[codec(index = 225)]
                        Mortal225(::core::primitive::u8),
                        #[codec(index = 226)]
                        Mortal226(::core::primitive::u8),
                        #[codec(index = 227)]
                        Mortal227(::core::primitive::u8),
                        #[codec(index = 228)]
                        Mortal228(::core::primitive::u8),
                        #[codec(index = 229)]
                        Mortal229(::core::primitive::u8),
                        #[codec(index = 230)]
                        Mortal230(::core::primitive::u8),
                        #[codec(index = 231)]
                        Mortal231(::core::primitive::u8),
                        #[codec(index = 232)]
                        Mortal232(::core::primitive::u8),
                        #[codec(index = 233)]
                        Mortal233(::core::primitive::u8),
                        #[codec(index = 234)]
                        Mortal234(::core::primitive::u8),
                        #[codec(index = 235)]
                        Mortal235(::core::primitive::u8),
                        #[codec(index = 236)]
                        Mortal236(::core::primitive::u8),
                        #[codec(index = 237)]
                        Mortal237(::core::primitive::u8),
                        #[codec(index = 238)]
                        Mortal238(::core::primitive::u8),
                        #[codec(index = 239)]
                        Mortal239(::core::primitive::u8),
                        #[codec(index = 240)]
                        Mortal240(::core::primitive::u8),
                        #[codec(index = 241)]
                        Mortal241(::core::primitive::u8),
                        #[codec(index = 242)]
                        Mortal242(::core::primitive::u8),
                        #[codec(index = 243)]
                        Mortal243(::core::primitive::u8),
                        #[codec(index = 244)]
                        Mortal244(::core::primitive::u8),
                        #[codec(index = 245)]
                        Mortal245(::core::primitive::u8),
                        #[codec(index = 246)]
                        Mortal246(::core::primitive::u8),
                        #[codec(index = 247)]
                        Mortal247(::core::primitive::u8),
                        #[codec(index = 248)]
                        Mortal248(::core::primitive::u8),
                        #[codec(index = 249)]
                        Mortal249(::core::primitive::u8),
                        #[codec(index = 250)]
                        Mortal250(::core::primitive::u8),
                        #[codec(index = 251)]
                        Mortal251(::core::primitive::u8),
                        #[codec(index = 252)]
                        Mortal252(::core::primitive::u8),
                        #[codec(index = 253)]
                        Mortal253(::core::primitive::u8),
                        #[codec(index = 254)]
                        Mortal254(::core::primitive::u8),
                        #[codec(index = 255)]
                        Mortal255(::core::primitive::u8),
                    }
                }
                pub mod header {
                    use super::runtime_types;
                    #[derive(
                        :: subxt :: ext :: codec :: Decode,
                        :: subxt :: ext :: codec :: Encode,
                        :: subxt :: ext :: scale_decode :: DecodeAsType,
                        :: subxt :: ext :: scale_encode :: EncodeAsType,
                        Debug,
                    )]
                    # [codec (crate = :: subxt :: ext :: codec)]
                    #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                    #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                    pub struct Header<_0> {
                        pub parent_hash: ::subxt::utils::H256,
                        #[codec(compact)]
                        pub number: _0,
                        pub state_root: ::subxt::utils::H256,
                        pub extrinsics_root: ::subxt::utils::H256,
                        pub digest: runtime_types::sp_runtime::generic::digest::Digest,
                    }
                }
            }
            pub mod transaction_validity {
                use super::runtime_types;
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub enum InvalidTransaction {
                    #[codec(index = 0)]
                    Call,
                    #[codec(index = 1)]
                    Payment,
                    #[codec(index = 2)]
                    Future,
                    #[codec(index = 3)]
                    Stale,
                    #[codec(index = 4)]
                    BadProof,
                    #[codec(index = 5)]
                    AncientBirthBlock,
                    #[codec(index = 6)]
                    ExhaustsResources,
                    #[codec(index = 7)]
                    Custom(::core::primitive::u8),
                    #[codec(index = 8)]
                    BadMandatory,
                    #[codec(index = 9)]
                    MandatoryValidation,
                    #[codec(index = 10)]
                    BadSigner,
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub enum TransactionSource {
                    #[codec(index = 0)]
                    InBlock,
                    #[codec(index = 1)]
                    Local,
                    #[codec(index = 2)]
                    External,
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub enum TransactionValidityError {
                    #[codec(index = 0)]
                    Invalid(runtime_types::sp_runtime::transaction_validity::InvalidTransaction),
                    #[codec(index = 1)]
                    Unknown(runtime_types::sp_runtime::transaction_validity::UnknownTransaction),
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub enum UnknownTransaction {
                    #[codec(index = 0)]
                    CannotLookup,
                    #[codec(index = 1)]
                    NoUnsignedValidator,
                    #[codec(index = 2)]
                    Custom(::core::primitive::u8),
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct ValidTransaction {
                    pub priority: ::core::primitive::u64,
                    pub requires: ::std::vec::Vec<::std::vec::Vec<::core::primitive::u8>>,
                    pub provides: ::std::vec::Vec<::std::vec::Vec<::core::primitive::u8>>,
                    pub longevity: ::core::primitive::u64,
                    pub propagate: ::core::primitive::bool,
                }
            }
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            pub enum DispatchError {
                #[codec(index = 0)]
                Other,
                #[codec(index = 1)]
                CannotLookup,
                #[codec(index = 2)]
                BadOrigin,
                #[codec(index = 3)]
                Module(runtime_types::sp_runtime::ModuleError),
                #[codec(index = 4)]
                ConsumerRemaining,
                #[codec(index = 5)]
                NoProviders,
                #[codec(index = 6)]
                TooManyConsumers,
                #[codec(index = 7)]
                Token(runtime_types::sp_runtime::TokenError),
                #[codec(index = 8)]
                Arithmetic(runtime_types::sp_arithmetic::ArithmeticError),
                #[codec(index = 9)]
                Transactional(runtime_types::sp_runtime::TransactionalError),
                #[codec(index = 10)]
                Exhausted,
                #[codec(index = 11)]
                Corruption,
                #[codec(index = 12)]
                Unavailable,
                #[codec(index = 13)]
                RootNotAllowed,
            }
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            pub struct ModuleError {
                pub index: ::core::primitive::u8,
                pub error: [::core::primitive::u8; 4usize],
            }
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            pub enum MultiSignature {
                #[codec(index = 0)]
                Ed25519(runtime_types::sp_core::ed25519::Signature),
                #[codec(index = 1)]
                Sr25519(runtime_types::sp_core::sr25519::Signature),
                #[codec(index = 2)]
                Ecdsa(runtime_types::sp_core::ecdsa::Signature),
            }
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            pub enum TokenError {
                #[codec(index = 0)]
                FundsUnavailable,
                #[codec(index = 1)]
                OnlyProvider,
                #[codec(index = 2)]
                BelowMinimum,
                #[codec(index = 3)]
                CannotCreate,
                #[codec(index = 4)]
                UnknownAsset,
                #[codec(index = 5)]
                Frozen,
                #[codec(index = 6)]
                Unsupported,
                #[codec(index = 7)]
                CannotCreateHold,
                #[codec(index = 8)]
                NotExpendable,
                #[codec(index = 9)]
                Blocked,
            }
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            pub enum TransactionalError {
                #[codec(index = 0)]
                LimitReached,
                #[codec(index = 1)]
                NoLayer,
            }
        }
        pub mod sp_version {
            use super::runtime_types;
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            pub struct RuntimeVersion {
                pub spec_name: ::std::string::String,
                pub impl_name: ::std::string::String,
                pub authoring_version: ::core::primitive::u32,
                pub spec_version: ::core::primitive::u32,
                pub impl_version: ::core::primitive::u32,
                pub apis: ::std::vec::Vec<([::core::primitive::u8; 8usize], ::core::primitive::u32)>,
                pub transaction_version: ::core::primitive::u32,
                pub state_version: ::core::primitive::u8,
            }
        }
        pub mod sp_weights {
            use super::runtime_types;
            pub mod weight_v2 {
                use super::runtime_types;
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct Weight {
                    #[codec(compact)]
                    pub ref_time: ::core::primitive::u64,
                    #[codec(compact)]
                    pub proof_size: ::core::primitive::u64,
                }
            }
            #[derive(
                :: subxt :: ext :: codec :: Decode,
                :: subxt :: ext :: codec :: Encode,
                :: subxt :: ext :: scale_decode :: DecodeAsType,
                :: subxt :: ext :: scale_encode :: EncodeAsType,
                Debug,
            )]
            # [codec (crate = :: subxt :: ext :: codec)]
            #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
            #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
            pub struct RuntimeDbWeight {
                pub read: ::core::primitive::u64,
                pub write: ::core::primitive::u64,
            }
        }
        pub mod starknet_api {
            use super::runtime_types;
            pub mod api_core {
                use super::runtime_types;
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct ClassHash(pub runtime_types::starknet_api::hash::StarkFelt);
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct CompiledClassHash(pub runtime_types::starknet_api::hash::StarkFelt);
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct ContractAddress(pub runtime_types::starknet_api::api_core::PatriciaKey);
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct EntryPointSelector(pub runtime_types::starknet_api::hash::StarkFelt);
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct EthAddress(pub ::subxt::utils::H160);
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct Nonce(pub runtime_types::starknet_api::hash::StarkFelt);
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct PatriciaKey(pub runtime_types::starknet_api::hash::StarkFelt);
            }
            pub mod hash {
                use super::runtime_types;
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct StarkFelt(pub [::core::primitive::u8; 32usize]);
            }
            pub mod state {
                use super::runtime_types;
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct StorageKey(pub runtime_types::starknet_api::api_core::PatriciaKey);
            }
            pub mod transaction {
                use super::runtime_types;
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct Calldata(pub ::std::vec::Vec<runtime_types::starknet_api::hash::StarkFelt>);
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct Event {
                    pub from_address: runtime_types::starknet_api::api_core::ContractAddress,
                    pub content: runtime_types::starknet_api::transaction::EventContent,
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct EventContent {
                    pub keys: ::std::vec::Vec<runtime_types::starknet_api::transaction::EventKey>,
                    pub data: runtime_types::starknet_api::transaction::EventData,
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct EventData(pub ::std::vec::Vec<runtime_types::starknet_api::hash::StarkFelt>);
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct EventKey(pub runtime_types::starknet_api::hash::StarkFelt);
                #[derive(
                    :: subxt :: ext :: codec :: CompactAs,
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct Fee(pub ::core::primitive::u128);
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct L2ToL1Payload(pub ::std::vec::Vec<runtime_types::starknet_api::hash::StarkFelt>);
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct MessageToL1 {
                    pub from_address: runtime_types::starknet_api::api_core::ContractAddress,
                    pub to_address: runtime_types::starknet_api::api_core::EthAddress,
                    pub payload: runtime_types::starknet_api::transaction::L2ToL1Payload,
                }
                #[derive(
                    :: subxt :: ext :: codec :: Decode,
                    :: subxt :: ext :: codec :: Encode,
                    :: subxt :: ext :: scale_decode :: DecodeAsType,
                    :: subxt :: ext :: scale_encode :: EncodeAsType,
                    Debug,
                )]
                # [codec (crate = :: subxt :: ext :: codec)]
                #[decode_as_type(crate_path = ":: subxt :: ext :: scale_decode")]
                #[encode_as_type(crate_path = ":: subxt :: ext :: scale_encode")]
                pub struct TransactionHash(pub runtime_types::starknet_api::hash::StarkFelt);
            }
        }
    }
}
