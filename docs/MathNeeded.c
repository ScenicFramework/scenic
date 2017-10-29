struct Vector2 : public XMFLOAT2
{
    Vector2() : XMFLOAT2(0.f, 0.f) {}
    explicit Vector2(float x) : XMFLOAT2( x, x ) {}
    Vector2(float _x, float _y) : XMFLOAT2(_x, _y) {}
    explicit Vector2(_In_reads_(2) const float *pArray) : XMFLOAT2(pArray) {}
    Vector2(FXMVECTOR V) { XMStoreFloat2( this, V ); }
    Vector2(const XMFLOAT2& V) { this->x = V.x; this->y = V.y; }
    explicit Vector2(const XMVECTORF32& F) { this->x = F.f[0]; this->y = F.f[1]; }

    operator XMVECTOR() const { return XMLoadFloat2( this ); }

    // Comparison operators
    bool operator == ( const Vector2& V ) const;
    bool operator != ( const Vector2& V ) const;

    // Assignment operators
    Vector2& operator= (const Vector2& V) { x = V.x; y = V.y; return *this; }
    Vector2& operator= (const XMFLOAT2& V) { x = V.x; y = V.y; return *this; }
    Vector2& operator= (const XMVECTORF32& F) { x = F.f[0]; y = F.f[1]; return *this; }
    Vector2& operator+= (const Vector2& V);
    Vector2& operator-= (const Vector2& V);
    Vector2& operator*= (const Vector2& V);
    Vector2& operator*= (float S);
    Vector2& operator/= (float S);

    // Unary operators
    Vector2 operator+ () const { return *this; }
    Vector2 operator- () const { return Vector2(-x, -y); }

    // Vector operations
    bool InBounds( const Vector2& Bounds ) const;

    float Length() const;
    float LengthSquared() const;

    float Dot( const Vector2& V ) const;
    void Cross( const Vector2& V, Vector2& result ) const;
    Vector2 Cross( const Vector2& V ) const;
    
    void Normalize();
    void Normalize( Vector2& result ) const;

    void Clamp( const Vector2& vmin, const Vector2& vmax );
    void Clamp( const Vector2& vmin, const Vector2& vmax, Vector2& result ) const;

    // Static functions
    static float Distance( const Vector2& v1, const Vector2& v2 );
    static float DistanceSquared( const Vector2& v1, const Vector2& v2 );

    static void Min( const Vector2& v1, const Vector2& v2, Vector2& result );
    static Vector2 Min( const Vector2& v1, const Vector2& v2 );

    static void Max( const Vector2& v1, const Vector2& v2, Vector2& result );
    static Vector2 Max( const Vector2& v1, const Vector2& v2 );

    static void Lerp( const Vector2& v1, const Vector2& v2, float t, Vector2& result );
    static Vector2 Lerp( const Vector2& v1, const Vector2& v2, float t );

    static void SmoothStep( const Vector2& v1, const Vector2& v2, float t, Vector2& result );
    static Vector2 SmoothStep( const Vector2& v1, const Vector2& v2, float t );

    static void Transform( const Vector2& v, const Quaternion& quat, Vector2& result );
    static Vector2 Transform( const Vector2& v, const Quaternion& quat );

    static void Transform( const Vector2& v, const Matrix& m, Vector2& result );
    static Vector2 Transform( const Vector2& v, const Matrix& m );

    static void Transform( const Vector2& v, const Matrix& m, Vector4& result );

    // Constants
    static const Vector2 Zero;
    static const Vector2 One;
    static const Vector2 UnitX;
    static const Vector2 UnitY;
};

// Binary operators
Vector2 operator+ (const Vector2& V1, const Vector2& V2);
Vector2 operator- (const Vector2& V1, const Vector2& V2);
Vector2 operator* (const Vector2& V1, const Vector2& V2);
Vector2 operator* (const Vector2& V, float S);
Vector2 operator/ (const Vector2& V1, const Vector2& V2);
Vector2 operator* (float S, const Vector2& V);

//------------------------------------------------------------------------------
// 3D vector
struct Vector3 : public XMFLOAT3
{
    Vector3() : XMFLOAT3(0.f, 0.f, 0.f) {}
    explicit Vector3(float x) : XMFLOAT3( x, x, x ) {}
    Vector3(float _x, float _y, float _z) : XMFLOAT3(_x, _y, _z) {}
    explicit Vector3(_In_reads_(3) const float *pArray) : XMFLOAT3(pArray) {}
    Vector3(FXMVECTOR V) { XMStoreFloat3( this, V ); }
    Vector3(const XMFLOAT3& V) { this->x = V.x; this->y = V.y; this->z = V.z; }
    explicit Vector3(const XMVECTORF32& F) { this->x = F.f[0]; this->y = F.f[1]; this->z = F.f[2]; }

    operator XMVECTOR() const { return XMLoadFloat3( this ); }

    // Comparison operators
    bool operator == ( const Vector3& V ) const;
    bool operator != ( const Vector3& V ) const;

    // Assignment operators
    Vector3& operator= (const Vector3& V) { x = V.x; y = V.y; z = V.z; return *this; }
    Vector3& operator= (const XMFLOAT3& V) { x = V.x; y = V.y; z = V.z; return *this; }
    Vector3& operator= (const XMVECTORF32& F) { x = F.f[0]; y = F.f[1]; z = F.f[2]; return *this; }
    Vector3& operator+= (const Vector3& V);
    Vector3& operator-= (const Vector3& V);
    Vector3& operator*= (const Vector3& V);
    Vector3& operator*= (float S);
    Vector3& operator/= (float S);

    // Unary operators
    Vector3 operator+ () const { return *this; }
    Vector3 operator- () const;

    // Vector operations
    bool InBounds( const Vector3& Bounds ) const;

    float Length() const;
    float LengthSquared() const;

    float Dot( const Vector3& V ) const;
    void Cross( const Vector3& V, Vector3& result ) const;
    Vector3 Cross( const Vector3& V ) const;

    void Normalize();
    void Normalize( Vector3& result ) const;

    void Clamp( const Vector3& vmin, const Vector3& vmax );
    void Clamp( const Vector3& vmin, const Vector3& vmax, Vector3& result ) const;

    // Static functions
    static float Distance( const Vector3& v1, const Vector3& v2 );
    static float DistanceSquared( const Vector3& v1, const Vector3& v2 );

    static void Min( const Vector3& v1, const Vector3& v2, Vector3& result );
    static Vector3 Min( const Vector3& v1, const Vector3& v2 );

    static void Max( const Vector3& v1, const Vector3& v2, Vector3& result );
    static Vector3 Max( const Vector3& v1, const Vector3& v2 );

    static void Lerp( const Vector3& v1, const Vector3& v2, float t, Vector3& result );
    static Vector3 Lerp( const Vector3& v1, const Vector3& v2, float t );

    static void SmoothStep( const Vector3& v1, const Vector3& v2, float t, Vector3& result );
    static Vector3 SmoothStep( const Vector3& v1, const Vector3& v2, float t );

    static void Transform( const Vector3& v, const Quaternion& quat, Vector3& result );
    static Vector3 Transform( const Vector3& v, const Quaternion& quat );

    static void Transform( const Vector3& v, const Matrix& m, Vector3& result );
    static Vector3 Transform( const Vector3& v, const Matrix& m );

    static void Transform( const Vector3& v, const Matrix& m, Vector4& result );

    // Constants
    static const Vector3 Zero;
    static const Vector3 One;
    static const Vector3 UnitX;
    static const Vector3 UnitY;
    static const Vector3 UnitZ;
};

// Binary operators
Vector3 operator+ (const Vector3& V1, const Vector3& V2);
Vector3 operator- (const Vector3& V1, const Vector3& V2);
Vector3 operator* (const Vector3& V1, const Vector3& V2);
Vector3 operator* (const Vector3& V, float S);
Vector3 operator/ (const Vector3& V1, const Vector3& V2);
Vector3 operator* (float S, const Vector3& V);

//------------------------------------------------------------------------------
// 4D vector
struct Vector4 : public XMFLOAT4
{
    Vector4() : XMFLOAT4(0.f, 0.f, 0.f, 0.f) {}
    explicit Vector4(float x) : XMFLOAT4( x, x, x, x ) {}
    Vector4(float _x, float _y, float _z, float _w) : XMFLOAT4(_x, _y, _z, _w) {}
    explicit Vector4(_In_reads_(4) const float *pArray) : XMFLOAT4(pArray) {}
    Vector4(FXMVECTOR V) { XMStoreFloat4( this, V ); }
    Vector4(const XMFLOAT4& V) { this->x = V.x; this->y = V.y; this->z = V.z; this->w = V.w; }
    explicit Vector4(const XMVECTORF32& F) { this->x = F.f[0]; this->y = F.f[1]; this->z = F.f[2]; this->w = F.f[3]; }

    operator XMVECTOR() const { return XMLoadFloat4( this ); }

    // Comparison operators
    bool operator == ( const Vector4& V ) const;
    bool operator != ( const Vector4& V ) const;

    // Assignment operators
    Vector4& operator= (const Vector4& V) { x = V.x; y = V.y; z = V.z; w = V.w; return *this; }
    Vector4& operator= (const XMFLOAT4& V) { x = V.x; y = V.y; z = V.z; w = V.w; return *this; }
    Vector4& operator= (const XMVECTORF32& F) { x = F.f[0]; y = F.f[1]; z = F.f[2]; w = F.f[3]; return *this; }
    Vector4& operator+= (const Vector4& V);
    Vector4& operator-= (const Vector4& V);
    Vector4& operator*= (const Vector4& V);
    Vector4& operator*= (float S);
    Vector4& operator/= (float S);

    // Unary operators
    Vector4 operator+ () const { return *this; }
    Vector4 operator- () const;

    // Vector operations
    bool InBounds( const Vector4& Bounds ) const;

    float Length() const;
    float LengthSquared() const;

    float Dot( const Vector4& V ) const;
    void Cross( const Vector4& v1, const Vector4& v2, Vector4& result ) const;
    Vector4 Cross( const Vector4& v1, const Vector4& v2 ) const;

    void Normalize();
    void Normalize( Vector4& result ) const;

    void Clamp( const Vector4& vmin, const Vector4& vmax );
    void Clamp( const Vector4& vmin, const Vector4& vmax, Vector4& result ) const;

    // Static functions
    static float Distance( const Vector4& v1, const Vector4& v2 );
    static float DistanceSquared( const Vector4& v1, const Vector4& v2 );

    static void Min( const Vector4& v1, const Vector4& v2, Vector4& result );
    static Vector4 Min( const Vector4& v1, const Vector4& v2 );

    static void Max( const Vector4& v1, const Vector4& v2, Vector4& result );
    static Vector4 Max( const Vector4& v1, const Vector4& v2 );

    static void Lerp( const Vector4& v1, const Vector4& v2, float t, Vector4& result );
    static Vector4 Lerp( const Vector4& v1, const Vector4& v2, float t );

    static void SmoothStep( const Vector4& v1, const Vector4& v2, float t, Vector4& result );
    static Vector4 SmoothStep( const Vector4& v1, const Vector4& v2, float t );

    static void Transform( const Vector2& v, const Quaternion& quat, Vector4& result );
    static Vector4 Transform( const Vector2& v, const Quaternion& quat );

    static void Transform( const Vector3& v, const Quaternion& quat, Vector4& result );
    static Vector4 Transform( const Vector3& v, const Quaternion& quat );

    static void Transform( const Vector4& v, const Quaternion& quat, Vector4& result );
    static Vector4 Transform( const Vector4& v, const Quaternion& quat );

    static void Transform( const Vector4& v, const Matrix& m, Vector4& result );
    static Vector4 Transform( const Vector4& v, const Matrix& m );

    // Constants
    static const Vector4 Zero;
    static const Vector4 One;
    static const Vector4 UnitX;
    static const Vector4 UnitY;
    static const Vector4 UnitZ;
    static const Vector4 UnitW;
};

// Binary operators
Vector4 operator+ (const Vector4& V1, const Vector4& V2);
Vector4 operator- (const Vector4& V1, const Vector4& V2);
Vector4 operator* (const Vector4& V1, const Vector4& V2);
Vector4 operator* (const Vector4& V, float S);
Vector4 operator/ (const Vector4& V1, const Vector4& V2);
Vector4 operator* (float S, const Vector4& V);

//------------------------------------------------------------------------------
// 4x4 Matrix (assumes right-handed cooordinates)
struct Matrix : public XMFLOAT4X4
{
    Matrix() : XMFLOAT4X4( 1.f,   0,   0,   0,
                             0, 1.f,   0,   0,
                             0,   0, 1.f,   0,
                             0,   0,   0, 1.f ) {}
    Matrix(float m00, float m01, float m02, float m03,
           float m10, float m11, float m12, float m13,
           float m20, float m21, float m22, float m23,
           float m30, float m31, float m32, float m33) : XMFLOAT4X4(m00, m01, m02, m03,
                                                                    m10, m11, m12, m13,
                                                                    m20, m21, m22, m23,
                                                                    m30, m31, m32, m33) {}
    explicit Matrix( const Vector3& r0, const Vector3& r1, const Vector3& r2 ) : XMFLOAT4X4( r0.x, r0.y, r0.z, 0,
                                                                                             r1.x, r1.y, r1.z, 0,
                                                                                             r2.x, r2.y, r2.z, 0,
                                                                                             0,       0,    0, 1.f ) {}
    explicit Matrix( const Vector4& r0, const Vector4& r1, const Vector4& r2, const Vector4& r3 ) : XMFLOAT4X4( r0.x, r0.y, r0.z, r0.w,
                                                                                                                r1.x, r1.y, r1.z, r1.w,
                                                                                                                r2.x, r2.y, r2.z, r2.w,
                                                                                                                r3.x, r3.y, r3.z, r3.w ) {}
    Matrix(const XMFLOAT4X4& M) { memcpy_s(this, sizeof(float)*16, &M, sizeof(XMFLOAT4X4)); }
    Matrix(const XMFLOAT3X3& M);
    Matrix(const XMFLOAT4X3& M);

    explicit Matrix(_In_reads_(16) const float *pArray) : XMFLOAT4X4(pArray) {}
    Matrix( CXMMATRIX M ) { XMStoreFloat4x4( this, M ); }

    operator XMMATRIX() const { return XMLoadFloat4x4( this ); }

    // Comparison operators
    bool operator == ( const Matrix& M ) const;
    bool operator != ( const Matrix& M ) const;

    // Assignment operators
    Matrix& operator= (const Matrix& M) { memcpy_s( this, sizeof(float)*16, &M, sizeof(float)*16 ); return *this; }
    Matrix& operator= (const XMFLOAT4X4& M) { memcpy_s( this, sizeof(float)*16, &M, sizeof(XMFLOAT4X4) ); return *this; }
    Matrix& operator= (const XMFLOAT3X3& M);
    Matrix& operator= (const XMFLOAT4X3& M);
    Matrix& operator+= (const Matrix& M);
    Matrix& operator-= (const Matrix& M);
    Matrix& operator*= (const Matrix& M);
    Matrix& operator*= (float S);
    Matrix& operator/= (float S);

    Matrix& operator/= (const Matrix& M);
        // Element-wise divide

    // Unary operators
    Matrix operator+ () const { return *this; }
    Matrix operator- () const;

    // Properties
    Vector3 Translation() const { return Vector3( _41, _42, _43 ); }
    void Translation( const Vector3& v ) { _41 = v.x; _42 = v.y; _43 = v.z; }

    // Matrix operations
    bool Decompose( Vector3& scale, Quaternion& rotation, Vector3& translation );

    Matrix Transpose() const;
    void Transpose( Matrix& result ) const;

    Matrix Invert() const;
    void Invert( Matrix& result ) const;

    float Determinant() const;

    // Static functions

    static Matrix CreateTranslation( const Vector3& position );
    static Matrix CreateTranslation( float x, float y, float z );

    static Matrix CreateScale( const Vector3& scales );
    static Matrix CreateScale( float xs, float ys, float zs );
    static Matrix CreateScale( float scale );

    static Matrix CreateRotationX( float radians );
    static Matrix CreateRotationY( float radians );
    static Matrix CreateRotationZ( float radians );

    static Matrix CreateFromAxisAngle( const Vector3& axis, float angle );

    static Matrix CreateFromQuaternion( const Quaternion& quat );

    static Matrix CreateFromYawPitchRoll( float yaw, float pitch, float roll );

    static void Lerp( const Matrix& M1, const Matrix& M2, float t, Matrix& result );
    static Matrix Lerp( const Matrix& M1, const Matrix& M2, float t );

    static void Transform( const Matrix& M, const Quaternion& rotation, Matrix& result );
    static Matrix Transform( const Matrix& M, const Quaternion& rotation );

    // Constants
    static const Matrix Identity;
};

// Binary operators
Matrix operator+ (const Matrix& M1, const Matrix& M2);
Matrix operator- (const Matrix& M1, const Matrix& M2);
Matrix operator* (const Matrix& M1, const Matrix& M2);
Matrix operator* (const Matrix& M, float S);
Matrix operator/ (const Matrix& M, float S);
Matrix operator/ (const Matrix& M1, const Matrix& M2);
    // Element-wise divide
Matrix operator* (float S, const Matrix& M);


WE PROBABLY DONT NEED PLANES JUST YET. I HONESTLY NEVER HAVE USED THIS
COMES IN HANDY IF YOU ARE DOING BSP TREE TYPES OF OPERATIONS
//-----------------------------------------------------------------------------
// Plane
struct Plane : public XMFLOAT4
{
    Plane() : XMFLOAT4(0.f, 1.f, 0.f, 0.f) {}
    Plane(float _x, float _y, float _z, float _w) : XMFLOAT4(_x, _y, _z, _w) {}
    Plane(const Vector3& normal, float d) : XMFLOAT4(normal.x, normal.y, normal.z, d) {}
    Plane(const Vector3& point1, const Vector3& point2, const Vector3& point3 );
    Plane(const Vector3& point, const Vector3& normal);
    explicit Plane(const Vector4& v) : XMFLOAT4(v.x, v.y, v.z, v.w) {}
    explicit Plane(_In_reads_(4) const float *pArray) : XMFLOAT4(pArray) {}
    Plane(FXMVECTOR V) { XMStoreFloat4( this, V ); }
    Plane(const XMFLOAT4& p) { this->x = p.x; this->y = p.y; this->z = p.z; this->w = p.w; }
    explicit Plane(const XMVECTORF32& F) { this->x = F.f[0]; this->y = F.f[1]; this->z = F.f[2]; this->w = F.f[3]; }

    operator XMVECTOR() const { return XMLoadFloat4( this ); }

    // Comparison operators
    bool operator == ( const Plane& p ) const;
    bool operator != ( const Plane& p ) const;

    // Assignment operators
    Plane& operator= (const Plane& p) { x = p.x; y = p.y; z = p.z; w = p.w; return *this; }
    Plane& operator= (const XMFLOAT4& p) { x = p.x; y = p.y; z = p.z; w = p.w; return *this; }
    Plane& operator= (const XMVECTORF32& F) { x = F.f[0]; y = F.f[1]; z = F.f[2]; w = F.f[3]; return *this; }

    // Properties
    Vector3 Normal() const { return Vector3( x, y, z ); }
    void Normal( const Vector3& normal ) { x = normal.x; y = normal.y; z = normal.z; }

    float D() const { return w; }
    void D(float d) { w = d; }

    // Plane operations
    void Normalize();
    void Normalize( Plane& result ) const;

    float Dot( const Vector4& v ) const;
    float DotCoordinate( const Vector3& position ) const;
    float DotNormal( const Vector3& normal ) const;

    // Static functions
    static void Transform( const Plane& plane, const Matrix& M, Plane& result );
    static Plane Transform( const Plane& plane, const Matrix& M );

    static void Transform( const Plane& plane, const Quaternion& rotation, Plane& result );
    static Plane Transform( const Plane& plane, const Quaternion& rotation );
        // Input quaternion must be the inverse transpose of the transformation
};

//------------------------------------------------------------------------------
// Quaternion
struct Quaternion : public XMFLOAT4
{
    Quaternion() : XMFLOAT4(0, 0, 0, 1.f) {}
    Quaternion( float _x, float _y, float _z, float _w ) : XMFLOAT4(_x, _y, _z, _w) {}
    Quaternion( const Vector3& v, float scalar ) : XMFLOAT4( v.x, v.y, v.z, scalar ) {}
    explicit Quaternion( const Vector4& v ) : XMFLOAT4( v.x, v.y, v.z, v.w ) {}
    explicit Quaternion(_In_reads_(4) const float *pArray) : XMFLOAT4(pArray) {}
    Quaternion(FXMVECTOR V) { XMStoreFloat4( this, V ); }
    Quaternion(const XMFLOAT4& q) { this->x = q.x; this->y = q.y; this->z = q.z; this->w = q.w; }
    explicit Quaternion(const XMVECTORF32& F) { this->x = F.f[0]; this->y = F.f[1]; this->z = F.f[2]; this->w = F.f[3]; }

    operator XMVECTOR() const { return XMLoadFloat4( this ); }

    // Comparison operators
    bool operator == ( const Quaternion& q ) const;
    bool operator != ( const Quaternion& q ) const;

    // Assignment operators
    Quaternion& operator= (const Quaternion& q) { x = q.x; y = q.y; z = q.z; w = q.w; return *this; }
    Quaternion& operator= (const XMFLOAT4& q) { x = q.x; y = q.y; z = q.z; w = q.w; return *this; }
    Quaternion& operator= (const XMVECTORF32& F) { x = F.f[0]; y = F.f[1]; z = F.f[2]; w = F.f[3]; return *this; }
    Quaternion& operator+= (const Quaternion& q);
    Quaternion& operator-= (const Quaternion& q);
    Quaternion& operator*= (const Quaternion& q);
    Quaternion& operator*= (float S);
    Quaternion& operator/= (const Quaternion& q);

    // Unary operators
    Quaternion operator+ () const { return *this; }
    Quaternion operator- () const;

    // Quaternion operations
    float Length() const;
    float LengthSquared() const;

    void Normalize();
    void Normalize( Quaternion& result ) const;

    void Conjugate();
    void Conjugate( Quaternion& result ) const;

    void Inverse( Quaternion& result ) const;

    float Dot( const Quaternion& Q ) const;

    // Static functions
    static Quaternion CreateFromAxisAngle( const Vector3& axis, float angle );
    static Quaternion CreateFromYawPitchRoll( float yaw, float pitch, float roll );
    static Quaternion CreateFromRotationMatrix( const Matrix& M );

    static void Lerp( const Quaternion& q1, const Quaternion& q2, float t, Quaternion& result );
    static Quaternion Lerp( const Quaternion& q1, const Quaternion& q2, float t );

    static void Slerp( const Quaternion& q1, const Quaternion& q2, float t, Quaternion& result );
    static Quaternion Slerp( const Quaternion& q1, const Quaternion& q2, float t );

    static void Concatenate( const Quaternion& q1, const Quaternion& q2, Quaternion& result );
    static Quaternion Concatenate( const Quaternion& q1, const Quaternion& q2 );

    // Constants
    static const Quaternion Identity;
};