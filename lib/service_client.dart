/// Support for doing something awesome.
///
/// More dartdocs go here.
library;

/// service core
export 'src/core/service_core.dart'
    show
        ServiceClient,
        ServiceClientConfig,
        ServiceRequest,
        ServiceResponse,
        ServiceProtocol;

/// http
export 'src/http/http_client.dart' show httpClient;
export 'src/http/http_service_client.dart' show HttpServiceClient;
export 'src/http/token.dart' show Token;
export 'src/http/token_vault.dart' show TokenVault;
export 'src/http/auth_exceptions.dart' show AuthReLoginException;
export 'src/http/http_exceptions.dart' show HttpClientException;
export 'src/http/storage/token_storage_adapter.dart'
    show TokenStorageAdapter, TokenStorageException;
export 'src/http/storage/memory_storage_adapter.dart' show MemoryStorageAdapter;
export 'src/http/storage/file_storage_adapter.dart'
    show
        FileStorageAdapter,
        AesGcmEncryptor,
        TokenEncryptor,
        PassphraseProvider;
