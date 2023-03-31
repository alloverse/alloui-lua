local modules = (...):gsub('%.[^%.]+$', '') .. "."
local Entity, componentClasses = unpack(require(modules.."entity"))
local tablex = require("pl.tablex")
local pretty = require("pl.pretty")
local ffi = require("ffi")

ffi.cdef [[

    void* malloc(size_t size);
    //char *strdup(const char *s); // this doesn't work on windows, use ffi.copy on a malloc'd buffer
    void free(void*);

    // cJSON.h
    typedef struct cJSON
    {
        /* next/prev allow you to walk array/object chains. Alternatively, use GetArraySize/GetArrayItem/GetObjectItem */
        struct cJSON *next;
        struct cJSON *prev;
        /* An array or object item will have a child pointer pointing to a chain of the items in the array/object. */
        struct cJSON *child;

        /* The type of the item, as above. */
        int type;

        /* The item's string, if type==cJSON_String  and type == cJSON_Raw */
        char *valuestring;
        /* writing to valueint is DEPRECATED, use cJSON_SetNumberValue instead */
        int valueint;
        /* The item's number, if type==cJSON_Number */
        double valuedouble;

        /* The item's name string, if this item is the child of, or is in the list of subitems of an object. */
        char *string;
    } cJSON;

    cJSON * cJSON_Parse(const char *value);
    char * cJSON_Print(const cJSON *item);
    char * cJSON_PrintUnformatted(const cJSON *item);
    void cJSON_Delete(cJSON *item);


    // math.h
    typedef union allo_vector
    {
        struct {
            double x, y, z;
        };
        double v[3];
    } allo_vector;
    
    extern allo_vector allo_vector_subtract(allo_vector l, allo_vector r);
    extern allo_vector allo_vector_add(allo_vector l, allo_vector r);
    extern allo_vector allo_vector_mul(allo_vector l, allo_vector r);
    extern allo_vector allo_vector_scale(allo_vector l, double r);
    extern allo_vector allo_vector_div(allo_vector l, allo_vector r);
    extern allo_vector allo_vector_normalize(allo_vector l);
    extern double allo_vector_dot(allo_vector l, allo_vector r);
    extern double allo_vector_length(allo_vector l);
    extern double allo_vector_angle(allo_vector l, allo_vector r);
    extern char *allo_vec_string(allo_vector l);
    
    typedef struct allo_rotation
    {
        double angle;
        allo_vector axis;
    } allo_rotation;
    
    
    // column major transformation matrix
    typedef union allo_m4x4
    {
        struct {
            double c1r1, c1r2, c1r3, c1r4, // 1st column
                c2r1, c2r2, c2r3, c2r4, // 2nd column, etc
                c3r1, c3r2, c3r3, c3r4,
                c4r1, c4r2, c4r3, c4r4;
        };
        double v[16];
    } allo_m4x4;
    
    extern allo_m4x4 allo_m4x4_identity();
    extern void allo_m4x4_set(allo_m4x4 *m, double c1r1, double c1r2, double c1r3, double c1r4, double c2r1, double c2r2, double c2r3, double c2r4, double c3r1, double c3r2, double c3r3, double c3r4, double c4r1, double c4r2, double c4r3, double c4r4);
    extern bool allo_m4x4_is_identity(allo_m4x4 m);
    extern allo_m4x4 allo_m4x4_translate(allo_vector translation);
    extern allo_m4x4 allo_m4x4_rotate(double angle, allo_vector axis);
    extern allo_m4x4 allo_m4x4_concat(allo_m4x4 l, allo_m4x4 r);
    extern allo_m4x4 allo_m4x4_add(allo_m4x4 l, allo_m4x4 r);
    extern allo_m4x4 allo_m4x4_scalar_multiply(allo_m4x4 l, double r);
    extern allo_m4x4 allo_m4x4_interpolate(allo_m4x4 l, allo_m4x4 r, double fraction);
    extern allo_m4x4 allo_m4x4_inverse(allo_m4x4 m);
    extern allo_vector allo_m4x4_transform(allo_m4x4 l, allo_vector r, bool positional);
    extern allo_vector allo_m4x4_get_position(allo_m4x4 l);
    extern allo_rotation allo_m4x4_get_rotation(allo_m4x4 l);
    extern bool allo_m4x4_equal(allo_m4x4 a, allo_m4x4 b, double sigma);
    extern char *allo_m4x4_string(allo_m4x4 m);








    

    // state.h
        
    typedef struct allo_client_pose_grab
    {
        char* entity; // which entity is being grabbed. null = none
        allo_m4x4 grabber_from_entity_transform;
    } allo_client_pose_grab;

    // #define ALLO_HAND_SKELETON_JOINT_COUNT 26
    typedef struct allo_client_hand_pose
    {
        allo_m4x4 matrix;
        allo_m4x4 skeleton[26];
        allo_client_pose_grab grab;
    } allo_client_hand_pose;

    typedef struct allo_client_plain_pose
    {
        allo_m4x4 matrix;
    } allo_client_plain_pose;

    typedef struct allo_client_poses
    {
        allo_client_plain_pose root;
        allo_client_plain_pose head;
        allo_client_plain_pose torso;
        allo_client_hand_pose left_hand;
        allo_client_hand_pose right_hand;
    } allo_client_poses;

    typedef struct allo_client_intent
    {
        char* entity_id; // which entity is this intent for
        uint8_t wants_stick_movement;
        double zmovement; // 1 = maximum speed forwards
        double xmovement; // 1 = maximum speed strafe right
        double yaw;       // rotation around x in radians
        double pitch;     // rotation around y in radians
        allo_client_poses poses;
        uint64_t ack_state_rev;
    } allo_client_intent;

    extern allo_client_intent *allo_client_intent_create();
    extern void allo_client_intent_free(allo_client_intent* intent);
    extern void allo_client_intent_clone(const allo_client_intent* original, allo_client_intent* destination);
    extern cJSON* allo_client_intent_to_cjson(const allo_client_intent *intent);
    extern allo_client_intent *allo_client_intent_parse_cjson(const cJSON* from);

    // generate an identifier of 'len'-1 chars, and null the last byte in str.
    extern void allo_generate_id(char *str, size_t len);

    typedef struct allo_entity
    {
        // Place-unique ID for this entity
        char *id;
        // Place's server-side ID for the agent that owns this entity
        char *owner_agent_id;

        // exposing implementation detail json isn't _great_ but best I got atm.
        // See https://github.com/alloverse/docs/blob/master/specifications/components.md for official
        // contained values
        cJSON *components;

        struct {
            struct allo_entity *le_next;
            struct allo_entity **le_prev;
        } pointers;
    } allo_entity;

    typedef struct { const char** data; size_t length, capacity; } allo_entity_id_vec;

    typedef struct allo_component_ref
    {
        const char *eid;
        const char *name;
        const cJSON *olddata;
        const cJSON *newdata;
    } allo_component_ref;

    typedef struct { allo_component_ref* data; size_t length, capacity; } allo_component_vec;

    typedef struct allo_state_diff
    {
        /// List of entities that have been created since last callback
        allo_entity_id_vec new_entities;
        /// List of entities that have disappeared since last callback
        allo_entity_id_vec deleted_entities;
        /// List of components that have been created since last callback, including any components of entities that just appeared.
        allo_component_vec new_components;
        /// List of components that have had one or more values changed
        allo_component_vec updated_components;
        /// List of components that have disappeared since last callback, including components of recently deleted entities.
        allo_component_vec deleted_components;
    } allo_state_diff;

    allo_entity *entity_create(const char *id);
    void entity_destroy(allo_entity *entity);

    extern allo_m4x4 entity_get_transform(allo_entity* entity);
    extern void entity_set_transform(allo_entity* entity, allo_m4x4 matrix);

    typedef struct allo_state
    {
        uint64_t revision;
        struct allo_entity_list {
	        struct allo_entity *lh_first;
        } entities;
    } allo_state;

    typedef enum allo_removal_mode
    {
        AlloRemovalCascade,
        AlloRemovalReparent,
    } allo_removal_mode;

    /// Add a new entity to the state based on a JSON specification of its components.
    /// @param agent_id: Arbitrary string representing the client that owns this entity. Only used server-side. strdup'd.
    /// @param spec: JSON with components. also key "children" with nested json of same structure. 
    ///             NOTE!! this reference is stolen, so you must not reference or free it!
    /// @param parent: entity ID of parent. will create "relationships" component if set.
    extern allo_entity* allo_state_add_entity_from_spec(allo_state* state, const char* agent_id, cJSON* spec, const char* parent);
    extern bool allo_state_remove_entity_id(allo_state *state, const char *eid, allo_removal_mode mode);
    extern bool allo_state_remove_entity(allo_state *state, allo_entity *removed_entity, allo_removal_mode mode);
    extern allo_entity* state_get_entity(allo_state* state, const char* entity_id);
    extern allo_entity* entity_get_parent(allo_state* state, allo_entity* entity);
    extern allo_m4x4 entity_get_transform_in_coordinate_space(allo_state* state, allo_entity* entity, allo_entity* space);
    extern allo_m4x4 state_convert_coordinate_space(allo_state* state, allo_m4x4 m, allo_entity* from_space, allo_entity* to_space);
    extern void allo_state_init(allo_state *state);
    extern void allo_state_destroy(allo_state *state);
    extern cJSON *allo_state_to_json(allo_state *state, bool include_agent_id);
    extern allo_state *allo_state_from_json(cJSON *state);
    extern void allo_state_diff_init(allo_state_diff *diff);
    extern void allo_state_diff_free(allo_state_diff *diff);
    extern void allo_state_diff_dump(allo_state_diff *diff);
    extern void allo_state_diff_mark_component_added(allo_state_diff *diff, const char *eid, const char *cname, const cJSON *comp);
    extern void allo_state_diff_mark_component_updated(allo_state_diff *diff, const char *eid, const char *cname, const cJSON *comp);
    /**
    * Describes an interaction to be sent or as received.
    * @field type: oneway, request, response or publication
    * @field sender_entity_id: the entity trying to interact with yours
    * @field receiver_entity_id: your entity being interacted with
    * @field request_id: The ID of this request or response
    * @field body: JSON list of interaction message
    */
    typedef struct allo_interaction
    {
        const char *type;
        const char *sender_entity_id;
        const char *receiver_entity_id;
        const char *request_id;
        const char *body;
    } allo_interaction;

    allo_interaction *allo_interaction_create(const char *type, const char *sender_entity_id, const char *receiver_entity_id, const char *request_id, const char *body);
    extern cJSON* allo_interaction_to_cjson(const allo_interaction* interaction);
    extern allo_interaction *allo_interaction_parse_cjson(const cJSON* from);
    extern allo_interaction *allo_interaction_clone(const allo_interaction *interaction);
    extern void allo_interaction_free(allo_interaction *interaction);

    /**
    * Initialize the Allonet library. Must be called before any other Allonet calls.
    */
    extern bool allo_initialize(bool redirect_stdout);
    /**
    * If you're linking liballonet_av, you also have to initialize that sub-library.
    */
    extern void allo_libav_initialize(void);

    /**
    * Run world simulation for a given state and known intents. Modifies state inline.
    * Will run the number of world iterations needed to get to server_time (or skip if too many)
    */
    extern void allo_simulate(allo_state* state, const allo_client_intent* intents[], int intent_count, double server_time, allo_state_diff *diff);










    // net.h
    typedef enum {
        allo_unreliable = 1,
        allo_reliable = 2,
    } allo_sendmode;

    typedef enum allochannel {
        CHANNEL_AUDIO = 0,      // unreliable
        CHANNEL_COMMANDS = 1,   // reliable
        CHANNEL_STATEDIFFS = 2, // unreliable
        CHANNEL_ASSETS = 3,     // reliable
        CHANNEL_VIDEO = 4,      // unreliable
        CHANNEL_CLOCK = 5,      // unreliable
        
        CHANNEL_COUNT
    } allochannel;

    extern const char *GetAllonetVersion(); // 3.1.4.g123abc
    extern const char *GetAllonetNumericVersion(); // 3.1.4
    extern const char *GetAllonetGitHash(); // g123abc
    extern int GetAllonetProtocolVersion(); // 3










    // client.h
    typedef enum alloerror
    {
        alloerror_connection_lost = 1000,
        alloerror_client_disconnected = 1001,
        alloerror_initialization_failure = 1002,
        alloerror_outdated_version = 1003,
        alloerror_failed_to_connect = 1004,
        alloerror_kicked_by_admin = 1005,
    } alloerror;
    
    typedef enum {
        /// Asset became available
        client_asset_state_now_available,
        /// Asset became unavailable
        client_asset_state_now_unavailable,
        /// Asset was requested but was not available
        client_asset_state_requested_unavailable,
    } client_asset_state;
    
    typedef struct allopixel {
      uint8_t r, g, b, a;
    } allopixel;
    
    typedef enum allopicture_format {
      allopicture_format_rgba8888,
      allopicture_format_bgra8888,
      allopicture_format_rgb1555,
      allopicture_format_xrgb8888,
      allopicture_format_rgb565,
    } allopicture_format;
    
    typedef struct allopicture {
      // actual pixel data (separately allocated).
      // If non-planar, set only planes[0] and set plane_count=1
      union {
        allopixel *rgba;
        uint16_t *rgb1555;
        uint32_t *xrgb;
        uint16_t *rgb565;
        uint8_t *monochrome;
      } planes[4];
      allopicture_format format;
      int width, height;
      int plane_count;
      // how many bytes per plane?
      int plane_byte_lengths[4];
      // how many bytes per row for a given plane?
      int plane_strides[4];
      // if null, planes[1-4] and the picture itself is free()d after use
      void (*free)(struct allopicture *p); 
      void *userdata;
    } allopicture;
    void allopicture_free(allopicture *picture);
    int allopicture_bpp(allopicture_format fmt);
    
    
    typedef struct alloclient alloclient;
    typedef struct alloclient {
        /** set this to get a callback when state changes. you don't own any of the
         *  data in the callbacks, and you must copy or use any data you need before
         *  the callback returns.
         * @param state     Full world state. Only valid during duration of callback.
         * @param diff      Changes in entities and components since last callback.
         */
        void (*state_callback)(
          alloclient *client, 
          allo_state *state, 
          allo_state_diff *diff
        );
    
        /** Set this to get a callback when another entity is trying to 
          * interact with one of your entities.
          * 
          * @param interaction: interaction received. Freed after callback;
          *                     copy it if you need to keep it.
          * @return bool: whether the caller should free the interaction afterwards (if you return false,
          *               you have to allo_interaction_free(interaction) yourself later).
          * @see https://github.com/alloverse/docs/blob/master/specifications/interactions.md
          */
        bool (*interaction_callback)(
            alloclient *client, 
            allo_interaction *interaction
        );
    
        /** Set this to get a callback when there is audio data available
         *  in an incoming audio stream track. Match it to a live_media component
         *  to figure out which entity is transmitting it, and thus at what
         *  location in 3d space to play it at. 
         * 
         *  @param track_id: which track/entity is transmitting this audio
         *  @param pcm: n samples of 48000 Hz mono PCM audio data (most often 480 samples, 10ms, 960 bytes)
         *  @param samples_decoded: 'n': how many samples in pcm
         *  @return bool: whether the caller should free the pcm afterwards (if you return false,
         *                you have to free(pcm) yourself later).
         */
        bool (*audio_callback)(
            alloclient *client,
            uint32_t track_id,
            int16_t pcm[],
            int32_t samples_decoded
        );
    
        bool (*video_callback)(
            alloclient *client,
            uint32_t track_id,
            allopixel pixels[],
            int32_t pixels_wide,
            int32_t pixels_high
        );
    
    
        /** You were disconnected from the server. This is
         *  never called in response to a local alloclient_disconnect;
         *  
         *  To free up resources, you must call alloclient_disconnect() after
         *  receiving this callback.
         */
        void (*disconnected_callback)(
           alloclient *client,
           alloerror code,
           const char *message
        );
    
        /*! 
         * Please provide the asset bytes between offset and offset+length using the `alloclient_asset_send` method.
         * You an respond by calling `alloclient_asset_send` either directly or at a later time. If you do not have any data for the requested asset then call `alloclient_asset_send` with NULL data and 0 length.
         * @example
         * void _asset_needs_data(alloclient *client, const char *asset_id, size_t offset, size_t length) {
         *  if (app_has_asset(asset_id)) {
         *   // get a pointer to the asset bytes
         *   alloclient_asset_send(client, asset_id, pointer + offset, offset, length, asset_size);
         *  } else {
         *   alloclient_asset_send(client, asset_id, NULL, offset, 0, 0);
         *  }
         * }
         * @note You may return less bytes than requested but you must respond with the requested `offset`
         * @param client The client object
         * @param asset_id An asset identifier
         * @param offset An offset into the data to start reading from
         * @param length The size requested
         */
        void (*asset_request_bytes_callback)(
          alloclient* client,
          const char* asset_id,
          size_t offset,
          size_t length
        );
    
        /*!
         * You have received data for an asset; write it to your cache.
         * You may request the next chunk of data as a response to this callback.
         * @note If there is an error in response to a request then this method will not be called.
         * @param client The client object
         * @param asset_id The asset identifier
         * @param buffer Bytes
         * @param length The number of bytes available in `buffer`.
         * @param total_size The total size of the asset.
         */
        void (*asset_receive_callback)(
          alloclient* client,
          const char* asset_id,
          const uint8_t* buffer,
          size_t offset,
          size_t length,
          size_t total_size
        );
        
        /*!
         * The state of an asset has changed
         */
        void (*asset_state_callback)(
          alloclient *client,
          const char *asset_id,
          client_asset_state state
        );
        
        // internal
        allo_state *_state;
        void *_internal;
        void *_internal2;
        void *_backref; // use this as a backref for callbacks  
        void *_simulation_cache;
    
        void (*clock_callback)(alloclient *client, double latency, double server_delta);
        double clock_latency;
        double clock_deltaToServer;
    
        bool (*alloclient_connect)(alloclient *client, const char *url, const char *identity, const char *avatar_desc);
        void (*alloclient_disconnect)(alloclient *client, int reason);
        bool (*alloclient_poll)(alloclient *client, int timeout_ms);
        void (*alloclient_send_interaction)(alloclient *client, allo_interaction *interaction);
        void (*alloclient_set_intent)(alloclient *client, const allo_client_intent *intent);
        void (*alloclient_send_audio)(alloclient *client, int32_t track_id, const int16_t *pcm, size_t sample_count);
        void (*alloclient_send_video)(alloclient *client, int32_t track_id, allopicture *picture);
        void (*alloclient_simulate)(alloclient* client);
        double (*alloclient_get_time)(alloclient* client);
        void (*alloclient_get_stats)(alloclient* client, char *buffer, size_t bufferlen);
        
        // -- Assets
            
        /// Let client know an asset is needed
        /// `asset_state_callback` will let you know when the asset is available or not found.
        /// @param asset_id The asset
        /// @param entity_id Optional entity that needs the asset.
        void (*alloclient_asset_request)(alloclient* client, const char* asset_id, const char* entity_id);
        
        void (*alloclient_asset_send)(alloclient *client, const char *asset_id, const uint8_t *data, size_t offset, size_t length, size_t total_size);
        
    } alloclient;
    
    /**
     * @param threaded: whether to run the network code inline and blocking on this thread, or on its own thread
     */
    alloclient *alloclient_create(bool threaded);
    
    
    /** Connect to an alloplace. Must be called once and only once on the returned alloclient from allo_create()
    * @param url: URL to an alloplace server, like alloplace://nevyn.places.alloverse.com
    * @param identity: JSON dict describing user, as per https://github.com/alloverse/docs/blob/master/specifications/README.md#agent-identity
    * @param avatar_desc: JSON dict describing components, as per "components" of https://github.com/alloverse/docs/blob/master/specifications/README.md#entity
    */
    bool alloclient_connect(alloclient *client, const char *url, const char *identity, const char *avatar_desc);
    
    /** Disconnect from an alloplace and free all internal state.
     *  `client` is free()d by this call. Call this to deallocate
     *  even if you're already disconnected remotely (and you
     *  notice from the disconnect callback).
     */
    void alloclient_disconnect(alloclient *client, int reason);
    
    /** Send and receive buffered data synchronously now. Loops over all queued
     network messages until the queue is empty.
     @param timeout_ms how many ms to wait for incoming messages before giving up. Default 10.
     @discussion Call regularly at 20hz to process incoming and outgoing network traffic.
     @return bool whether any messages were parsed
     */
    bool alloclient_poll(alloclient *client, int timeout_ms);
    
    
    /** Have one of your entites interact with another entity.
      * Use this same method to send back a response when you get a request. 
      * 
      * @param interaction: interaction to send. Will not be held, will not be
      *                     freed.
      * @see https://github.com/alloverse/docs/blob/master/specifications/interactions.md
      */
    void alloclient_send_interaction(alloclient *client, allo_interaction *interaction);
    
    /** Change this client's movement/action intent.
     *  @see https://github.com/alloverse/docs/blob/master/specifications/README.md#entity-intent
     */
    void alloclient_set_intent(alloclient *client, const allo_client_intent *intent);
    
    /** Transmit audio from an entity, e g microphone audio for
      * voice communication. You must send the interaction `allocate_track` to receive a
      * track_id to send from beforehand, to associate a particular audio stream with a specific
      * entity.
      * Everyone nearby your entity will hear the audio.
      * @param track_id Track allocated from `allocate_track` interaction on which to send audio
      * @param pcm 48000 Hz mono PCM audio data
      * @param sample_count Number of samples in `pcm`. Must be 480 or 960 (10ms or 20ms worth of audio)
      *   
      */
    void alloclient_send_audio(alloclient *client, int32_t track_id, const int16_t *pcm, size_t sample_count);

    // TODO: docs
    void alloclient_send_audio_data(alloclient *client, int32_t track_id, const char *pcmdata, size_t sample_count);
    
    /** Transmit video from an entity, e g camera video or screen sharing.
     *  Like alloclient_send_audio, you must `allocate_track` first to receive
     *  a track_id.
     * 
     * @param track_id  Track allocated from `allocate_track` interaction on which to send video
     * @param picture   Picture data for this frame. On memory management: calling this method transfers
     *                  memory ownership to this library. The picture will later either be free()'d if
     *                  the `free` callback is null, or the callback is called to give you a chance to
     *                  recycle the memory or use some custom method of freeing it.
     */
    void alloclient_send_video(alloclient *client, int32_t track_id, allopicture *picture);

    // TODO: docs
    void alloclient_send_video_pixels(alloclient *client, int32_t track_id, const char *pixels, int width, int height, allopicture_format format, int stride);
    
    /*!
     * Request an asset. This might be a texture, a model, a sound or something that
     * you need. You might need it because it's referenced from a component in an entity
     * that you want to draw. If you know which entity is referencing it, you can
     * send it as `entity_id`, but that's optional.
     */
    void alloclient_asset_request(alloclient* client, const char* asset_id, const char* entity_id);
    
    
    /*!
     * Respond to an asset_request_callback
     * Send NULL as `data` if you do not have the requested byte range
     */
    void alloclient_asset_send(alloclient *client, const char *asset_id, const uint8_t *data, size_t offset, size_t length, size_t total_size);
    
    /**
      * Run allo_simulate() on the internal world state with our latest intent, so that we get local interpolation
      * of hand movement etc
      */
    void alloclient_simulate(alloclient* client);
    
    /** Get current estimated alloplace time that is hopefully uniform across all
      * connected clients; or best-effort if it's out of sync.
      * @return seconds since some arbitrary point in the past
      */
    double alloclient_get_time(alloclient* client);
    
    void alloclient_get_stats(alloclient* client, char *buffer, size_t bufferlen);
    allo_state *alloclient_get_state(alloclient *client);
    
    // util.h
    int64_t get_ts_mono(void);
    double get_ts_monod(void);
    uint64_t allo_create_random_seed(void);


    void allosim_simulate_root_pose(allo_state *state, const char *avatar_id, float dt, allo_client_intent *intent);

    


    //// server.h
    static const int allo_udp_port = 21337;
    static const int allo_client_count_max = 128;

    // excluding null terminating byte
    // #define AGENT_ID_LENGTH 16

    typedef struct alloserver_client {
        allo_client_intent *intent;
        char *avatar_entity_id;
        char agent_id[/*AGENT_ID_LENGTH*/ 16+1];
        cJSON *identity;

        // private
        void *_internal;
        void *_backref;
        //LIST_ENTRY(alloserver_client) pointers;
    } alloserver_client;

    typedef struct alloserver alloserver;
    struct alloserver {
        // handle incoming events for at most duration_ms. returns true if event was handled
        bool (*interbeat)(alloserver *serv, int duration_ms);
        
        // raw json as delivered from client (intent or interaction)
        void (*raw_indata_callback)(alloserver *serv, alloserver_client *client, allochannel channel, const uint8_t *data, size_t data_length);
        
        // list of clients changed; either `added` or `removed` is set.
        void (*clients_callback)(alloserver *serv, alloserver_client *added, alloserver_client *removed);

        // internal
        void (*send)(alloserver *serv, alloserver_client *client, allochannel channel, const uint8_t *buf, int len);
        allo_state state;

        void *_backref; // use this as a backref for callbacks
        void *_internal; // used within server.c to hide impl
        int _port;

        //LIST_HEAD(alloserver_client_list, alloserver_client) clients;
    };

    // send 0 for any host or any port
    alloserver *allo_listen(int listenhost, int port);

    struct _ENetPacket;

    void alloserv_send_enet(alloserver *serv, alloserver_client *client, allochannel channel, struct _ENetPacket *packet);

    // immediately shutdown the server
    void alloserv_stop(alloserver* serv);

    // disconnect one client for one reason, first transmitting all its messages.
    // clients_callback() is called once the disconnection is successful.
    void alloserv_disconnect(alloserver *serv, alloserver_client *client, int reason_code);

    size_t alloserv_get_client_stats(alloserver* serv, alloserver_client *client, char *buffer, size_t bufferlen, bool header);

    void alloserv_get_stats(alloserver* serv, char *buffer, size_t bufferlen);

    // run a minimal standalone C server. returns when it shuts down. false means it broke.
    bool alloserv_run_standalone(const char *public_hostname, int listenhost, int port, const char *placename);

    // start it but don't run it. returns allosocket.
    alloserver *alloserv_start_standalone(const char *public_hostname, int listenhost, int port, const char *placename);
    // call this frequently to run it. returns false if server has broken and shut down; then you should call stop on it to clean up.
    bool alloserv_poll_standalone(int allosocket);
    // and then call this to stop and clean up state.
    void alloserv_stop_standalone();

    const char *alloserv_describe_client(alloserver_client *client);


    // internal
    int allo_socket_for_select(alloserver *server);

    // allo_gltf.c
    typedef struct {
        float x, y, z;
    } allo_gltf_point;
    
    typedef struct {
        allo_gltf_point min;
        allo_gltf_point max;
    } allo_gltf_bb;
    bool allo_gltf_load(const unsigned char *bytes, uint32_t size, const char *name_);
    bool allo_gltf_unload(const unsigned char *bytes, uint32_t size, const char *name_);
    bool allo_gltf_get_aabb(const char *name_, allo_gltf_bb *bb);
    allo_m4x4 allo_gltf_get_node_transform(const unsigned char *bytes, uint64_t size, const char *node_name);

    

    /// asset.h
    char *asset_generate_identifier(const uint8_t *bytes, size_t size);

    typedef enum LogType { DEBUG, INFO, ERROR } LogType;
    void allo_log(LogType type, const char *module, const char *identifiers, const char *format, ...);
]]

local function makeLog(allonet)
    _G["allo_log"] = function (logtype, module, identifiers, message)
        if logtype == "DEBUG" then logtype = 0 end
        if logtype == "INFO" then logtype = 1 end
        if logtype == "ERROR" then logtype = 2 end
        assert(type(logtype) == "number")
        assert(module ~= nil)
        assert(message ~= nil)
        assert(message ~= "")
        allonet.allo_log(logtype, "lua/"..module, identifiers, message);
    end
end


function CreateAllonetHandle()
    if not allonet then 
        allonet = ffi.C
    end
    local allonet_exists_in_current_process, _ = pcall(function()
        return allonet.alloclient_create
    end)
    if not allonet_exists_in_current_process then
        print("Loading allonet through dynamic loading")
        allonet = ffi.load('allonet')
    else
        print("Loading allonet through the current process")
    end
    math.randomseed( tonumber(allonet.allo_create_random_seed()) )

    makeLog(allonet)

    return allonet
end

return CreateAllonetHandle()
