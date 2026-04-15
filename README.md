# Purchase Order Management App

## Overview
This Purchase Order Management App allows users to efficiently manage purchase orders, track inventory, and analyze spending patterns. The application is designed to streamline the procurement process from order creation to approval and management.

## Application Architecture
The app follows a modular architecture to promote maintainability and ease of development. The key components include:
1. **Frontend**: Built with React, the frontend provides a user-friendly interface for interacting with purchase orders.
2. **Backend**: The backend is developed using Node.js with Express.js, providing APIs to handle order management.
3. **Database**: Data is stored in MongoDB, allowing for efficient querying and data management.
4. **Authentication**: User authentication is managed via JWT tokens ensuring secure access to the application.
5. **Testing**: Unit and integration tests are implemented to ensure code quality and reliability.

## Features
- **User Management**: Role-based access control for managing user permissions.
- **Order Creation**: Create and manage purchase orders, including item descriptions and quantities.
- **Order Tracking**: Monitor order status from creation to completion.
- **Inventory Management**: Keep track of stock levels and alert users of low inventory.
- **Reporting**: Generate reports on spending, order frequency, and supplier performance.

## Deployment Instructions
1. **Clone the Repository**:
   ```bash
   git clone https://github.com/sanamjena/Purchase-Order-App.git
   cd Purchase-Order-App
   ```

2. **Set Up Environment Variables**:
   Create a `.env` file in the root directory with the following variables:
   ```
   PORT=5000
   MONGODB_URI=<your_mongodb_connection_string>
   JWT_SECRET=<your_jwt_secret>
   ```

3. **Install Dependencies**:
   Install required dependencies for both frontend and backend:
   ```bash
   npm install
   cd client
   npm install
   ```

4. **Run the Application**:
   Start the server and client:
   ```bash
   npm run dev
   ```
   The application will be available at `http://localhost:5000`.

## Usage Guidelines
- **Login**: Users must log in with their credentials to access the application.
- **Creating an Order**: Navigate to the "Create Order" section, fill in the required details, and submit.
- **Viewing Orders**: Users can view all orders in the "Orders" section of the application.
- **Integrating with Suppliers**: Use the "Suppliers" tab to manage supplier information and sync orders.

## Contributing
Contributions to the project are welcome! Please submit a pull request with your proposed changes. Make sure to follow the coding standards and ensure your changes include relevant tests.

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contact
For any questions or issues, please reach out to the repository owner at sanamjena.