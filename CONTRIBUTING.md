# Contributing to Electric Meter Billing

First off, thank you for considering contributing to Electric Meter Billing! It's people like you that make this project better.

## Code of Conduct

This project and everyone participating in it is governed by our Code of Conduct. By participating, you are expected to uphold this code.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the issue list as you might find out that you don't need to create one. When you are creating a bug report, please include as many details as possible:

* Use a clear and descriptive title
* Describe the exact steps which reproduce the problem
* Provide specific examples to demonstrate the steps
* Describe the behavior you observed after following the steps
* Explain which behavior you expected to see instead and why
* Include screenshots if possible
* Include your environment details (OS, Flutter version, etc.)

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, please include:

* Use a clear and descriptive title
* Provide a step-by-step description of the suggested enhancement
* Provide specific examples to demonstrate the steps
* Describe the current behavior and explain which behavior you expected to see instead
* Explain why this enhancement would be useful
* List some other applications where this enhancement exists, if applicable

### Pull Requests

* Fork the repo and create your branch from `main`
* If you've added code that should be tested, add tests
* If you've changed APIs, update the documentation
* Ensure the test suite passes
* Make sure your code lints
* Issue that pull request!

## Development Process

1. Fork the repository
2. Create a new branch for your feature/fix
3. Write your code following our coding standards
4. Write or update tests as needed
5. Update documentation as needed
6. Submit a pull request

### Coding Standards

* Follow the [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
* Use the project's analysis options
* Write meaningful commit messages
* Keep code modular and maintainable
* Comment complex logic
* Update documentation for API changes

### Project Structure

```
lib/
├── data/          # Data layer (repositories implementations, models)
├── domain/        # Domain layer (entities, repository interfaces)
├── presentation/  # Presentation layer (UI, BLoCs)
└── services/      # Application services
```

### Testing

* Write unit tests for repositories and BLoCs
* Write widget tests for UI components
* Write integration tests for critical user flows
* Maintain test coverage

## Documentation

* Update README.md if needed
* Document new features
* Update CHANGELOG.md
* Comment complex code sections
* Update API documentation

## Community

* Join our discussions
* Help others in issues
* Review pull requests
* Share your ideas

## Questions?

Feel free to contact the project maintainers if you have any questions.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.